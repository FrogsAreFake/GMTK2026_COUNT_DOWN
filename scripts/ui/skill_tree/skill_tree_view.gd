extends Control
class_name SkillTreeView

## Attach to the root Control of your skill tree screen. Expected scene tree:
##
## SkillTreeView (Control, full rect, Clip Contents = ON)  <- this script
## ├── Background (ColorRect, white, fills the whole view)
## ├── World (Control)                                     <- gets panned/zoomed
## │   ├── ConnectionLines (Control, script: connection_lines.gd, Mouse Filter = Ignore)
## │   └── (SkillNodeButton instances get added here at runtime)
## ├── Tooltip (instance of SkillTooltip.tscn, full-width bar anchored to the bottom,
## │   Mouse Filter = Ignore, initially hidden)
## └── PointsPanel (PanelContainer, top-right, shows remaining skill points)

@export var skill_node_scene: PackedScene       ## SkillNode.tscn (has skill_node_button.gd)
@export var skills: Array[SkillData] = []       ## drag your .tres skill resources in here
@export var cell_size: Vector2 = Vector2(96, 96)
@export var node_size: Vector2 = Vector2(72, 72)
@export var min_zoom: float = 0.5
@export var max_zoom: float = 1.5
@export var zoom_step: float = 0.1

@onready var world: Control = $World
@onready var connections: ConnectionLines = $World/ConnectionLines
@onready var tooltip: SkillTooltip = $Tooltip
@onready var points_label: Label = $PointsPanel/Margin/PointsLabel

var _skill_nodes: Dictionary = {} # skill_id -> SkillNodeButton
var _zoom: float = 1.0

func _ready() -> void:
	tooltip.hide()
	connections.view = self
	SkillTreeManager.currency_changed.connect(_on_currency_changed)
	_update_points_label()
	_build_tree()
	_center_view()

func _build_tree() -> void:
	for skill in skills:
		var node := skill_node_scene.instantiate() as SkillNodeButton
		world.add_child(node)
		node.size = node_size
		# grid_position is in cells; convert to pixels and center the node on that point
		node.position = Vector2(skill.grid_position) * cell_size - node_size * 0.5
		node.setup(skill)
		node.hovered.connect(_on_skill_hovered)
		node.unhovered.connect(_on_skill_unhovered)
		node.purchase_attempted.connect(_on_purchase_attempted)
		node.dragged.connect(_on_node_dragged)
		_skill_nodes[skill.id] = node
	connections.queue_redraw()

func _center_view() -> void:
	world.position = size * 0.5

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				SkillTreePanState.begin_press(event.global_position)
			else:
				SkillTreePanState.end_press()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_at(event.position, zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_at(event.position, -zoom_step)
	elif event is InputEventMouseMotion:
		SkillTreePanState.update_press(event.global_position)
		if SkillTreePanState.dragging:
			world.position += event.relative
			tooltip.hide()

func _zoom_at(local_pos: Vector2, delta: float) -> void:
	var old_zoom := _zoom
	_zoom = clamp(_zoom + delta, min_zoom, max_zoom)
	var factor := _zoom / old_zoom
	# Keep the point under the cursor fixed in place while zooming.
	world.position = local_pos - (local_pos - world.position) * factor
	world.scale = Vector2.ONE * _zoom

func _on_skill_hovered(skill: SkillData, _screen_pos: Vector2) -> void:
	var level := SkillTreeManager.get_level(skill.id)
	var cost := SkillTreeManager.get_next_cost(skill)
	tooltip.show_for(skill, level, cost)

func _on_skill_unhovered() -> void:
	tooltip.hide()

func _on_node_dragged(relative: Vector2) -> void:
	world.position += relative
	tooltip.hide()

func _on_currency_changed(_new_amount: int) -> void:
	_update_points_label()

func _update_points_label() -> void:
	points_label.text = "Skill Points: %d" % SkillTreeManager.currency

func _on_purchase_attempted(skill: SkillData) -> void:
	SkillTreeManager.purchase(skill) # no-op if requirements/cost aren't met
	connections.queue_redraw()
	if tooltip.visible:
		_on_skill_hovered(skill, Vector2.ZERO) # refresh cost/level text immediately

## Called by ConnectionLines._draw(). Draws a line from every prerequisite to its dependent,
## clipped to the borders of each node's rect (rather than running center-to-center).
func draw_connections(canvas: CanvasItem) -> void:
	for skill in skills:
		if skill.prerequisite_ids.is_empty():
			continue
		var to_node: SkillNodeButton = _skill_nodes.get(skill.id)
		if to_node == null:
			continue
		var to_center: Vector2 = to_node.position + to_node.size * 0.5
		for prereq_id in skill.prerequisite_ids:
			var from_node: SkillNodeButton = _skill_nodes.get(prereq_id)
			if from_node == null:
				continue
			var from_center: Vector2 = from_node.position + from_node.size * 0.5
			var dir := to_center - from_center
			if dir.is_zero_approx():
				continue
			var from_pos := _rect_border_point(from_center, from_node.size, dir)
			var to_pos := _rect_border_point(to_center, to_node.size, -dir)
			var unlocked_line := SkillTreeManager.get_level(prereq_id) > 0
			var color := Color(0.25, 0.22, 0.15) if unlocked_line else Color(0.75, 0.75, 0.75)
			canvas.draw_line(from_pos, to_pos, color, 3.0)

## Returns the point where a ray from `rect_center` in direction `dir` exits the axis-aligned
## rectangle of size `rect_size` centered on `rect_center` — i.e. the point on that rect's border.
func _rect_border_point(rect_center: Vector2, rect_size: Vector2, dir: Vector2) -> Vector2:
	var d := dir.normalized()
	var half := rect_size * 0.5
	var t_x: float = half.x / absf(d.x) if not is_zero_approx(d.x) else INF
	var t_y: float = half.y / absf(d.y) if not is_zero_approx(d.y) else INF
	var t: float = min(t_x, t_y)
	return rect_center + d * t
