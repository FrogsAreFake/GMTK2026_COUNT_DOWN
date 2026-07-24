extends Control
class_name SkillTreeView

## Attach to the root Control of your skill tree screen. Expected scene tree:
##
## SkillTreeView (Control, full rect, Clip Contents = ON)  <- this script
## ├── World (Control)                                     <- gets panned/zoomed
## │   ├── ConnectionLines (Control, script: connection_lines.gd, Mouse Filter = Ignore)
## │   └── (SkillNodeButton instances get added here at runtime)
## └── Tooltip (instance of SkillTooltip.tscn, Mouse Filter = Ignore, initially hidden)

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

var _skill_nodes: Dictionary = {} # skill_id -> SkillNodeButton
var _zoom: float = 1.0

func _ready() -> void:
	tooltip.hide()
	connections.view = self
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
	_position_tooltip()

func _position_tooltip() -> void:
	var pos := get_global_mouse_position() + Vector2(18, 18)
	# Keep it on screen
	var vp_size := get_viewport_rect().size
	pos.x = min(pos.x, vp_size.x - tooltip.size.x - 8)
	pos.y = min(pos.y, vp_size.y - tooltip.size.y - 8)
	tooltip.global_position = pos

func _on_skill_unhovered() -> void:
	tooltip.hide()

func _on_purchase_attempted(skill: SkillData) -> void:
	SkillTreeManager.purchase(skill) # no-op if requirements/cost aren't met
	connections.queue_redraw()
	if tooltip.visible:
		_on_skill_hovered(skill, Vector2.ZERO) # refresh cost/level text immediately

## Called by ConnectionLines._draw(). Draws a line from every prerequisite to its dependent.
func draw_connections(canvas: CanvasItem) -> void:
	for skill in skills:
		if skill.prerequisite_ids.is_empty():
			continue
		var to_node: SkillNodeButton = _skill_nodes.get(skill.id)
		if to_node == null:
			continue
		var to_pos: Vector2 = to_node.position + to_node.size * 0.5
		for prereq_id in skill.prerequisite_ids:
			var from_node: SkillNodeButton = _skill_nodes.get(prereq_id)
			if from_node == null:
				continue
			var from_pos: Vector2 = from_node.position + from_node.size * 0.5
			var unlocked_line := SkillTreeManager.get_level(prereq_id) > 0
			var color := Color.WHITE if unlocked_line else Color(0.4, 0.4, 0.4)
			canvas.draw_line(from_pos, to_pos, color, 3.0)
