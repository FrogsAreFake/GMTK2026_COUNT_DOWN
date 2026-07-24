extends Control

## Controller for the skill tree page. Collects every SkillNode under the
## "SkillNodes" container, manages skill points, unlock logic and the info
## panel, and keeps the connection lines in sync with the current state.

@export var starting_points: int = 5

var _skills: Array[SkillNode] = []
var _hovered: SkillNode = null
var _points: int = 0
var _is_panning: bool = false
var _pan_offset: Vector2 = Vector2.ZERO
var _center_offset: Vector2 = Vector2.ZERO
var _last_mouse_position: Vector2 = Vector2.ZERO

@onready var _tree_canvas: Control = $TreeCanvas
@onready var _connections: SkillConnections = $TreeCanvas/Connections
@onready var _points_label: Label = $HeaderPanel/HeaderMargin/PointsLabel
@onready var _info_panel: PanelContainer = $InfoPanel
@onready var _info_name: Label = $InfoPanel/InfoMargin/InfoBox/TextBox/SkillName
@onready var _info_cost: Label = $InfoPanel/InfoMargin/InfoBox/SkillCost
@onready var _info_desc: Label = $InfoPanel/InfoMargin/InfoBox/TextBox/SkillDescription


func _ready() -> void:
	_points = starting_points
	_collect_skills($TreeCanvas/SkillNodes)
	for s in _skills:
		s.skill_selected.connect(_on_skill_selected)
		s.mouse_entered.connect(_on_skill_mouse_entered.bind(s))
		s.mouse_exited.connect(_on_skill_mouse_exited.bind(s))
	for s in _skills:
		if s.unlocked_from_start:
			s.set_state(SkillNode.State.UNLOCKED)
	_info_panel.visible = false
	_refresh_states()
	_update_points_label()
	_hide_info()
	# Wait one frame so containers have finished laying out before we read
	# node centers to draw the connection lines.
	await get_tree().process_frame
	_connections.setup(_skills)
	_recalculate_center_offset()
	_apply_tree_position()


func _collect_skills(root: Node) -> void:
	for child in root.get_children():
		if child is SkillNode:
			_skills.append(child as SkillNode)


func _on_skill_selected(skill: SkillNode) -> void:
	if skill.state != SkillNode.State.AVAILABLE:
		return
	if _points < skill.cost:
		return
	_points -= skill.cost
	skill.set_state(SkillNode.State.UNLOCKED)
	_refresh_states()
	_update_points_label()
	if _hovered == skill:
		_show_info(skill)


## Recompute LOCKED / AVAILABLE state for every skill that is not yet unlocked.
func _refresh_states() -> void:
	for s in _skills:
		if s.state == SkillNode.State.UNLOCKED:
			continue
		if _prerequisites_met(s):
			s.set_state(SkillNode.State.AVAILABLE)
		else:
			s.set_state(SkillNode.State.LOCKED)
	_connections.queue_redraw()


func _prerequisites_met(skill: SkillNode) -> bool:
	for pre_path in skill.prerequisites:
		var pre := skill.get_node_or_null(pre_path) as SkillNode
		if pre == null:
			continue
		if not pre.is_unlocked():
			return false
	return true


func _update_points_label() -> void:
	_points_label.text = "Skill Points: %d" % _points


func _show_info(skill: SkillNode) -> void:
	if skill == null:
		_info_name.text = ""
		_info_cost.text = ""
		_info_desc.text = ""
		return

	_info_panel.visible = true
	_info_name.text = skill.skill_name
	_info_cost.text = "Cost: %d point(s)" % skill.cost
	_info_desc.text = skill.description


func _hide_info() -> void:
	_show_info(null)
	_info_panel.visible = false


func _on_skill_mouse_entered(skill: SkillNode) -> void:
	_hovered = skill
	_show_info(skill)


func _on_skill_mouse_exited(skill: SkillNode) -> void:
	if _hovered != skill:
		return
	_hovered = null
	_hide_info()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if _is_pointer_over_skill(mb.position):
					return
				_is_panning = true
				_last_mouse_position = mb.position
				accept_event()
			else:
				_is_panning = false
	if event is InputEventMouseMotion and _is_panning:
		var mm := event as InputEventMouseMotion
		_pan_offset += mm.position - _last_mouse_position
		_last_mouse_position = mm.position
		_apply_tree_position()
		accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_recalculate_center_offset()
		_apply_tree_position()


func _recalculate_center_offset() -> void:
	if _skills.is_empty():
		_center_offset = Vector2.ZERO
		return
	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)
	for skill in _skills:
		min_pos = min_pos.min(skill.position)
		max_pos = max_pos.max(skill.position + skill.size)
	var skills_center := (min_pos + max_pos) * 0.5
	_center_offset = size * 0.5 - skills_center


func _apply_tree_position() -> void:
	if _tree_canvas != null:
		_tree_canvas.position = _center_offset + _pan_offset


func _is_pointer_over_skill(pointer_position: Vector2) -> bool:
	var pointer_global := get_global_transform() * pointer_position
	for skill in _skills:
		if skill.get_global_rect().has_point(pointer_global):
			return true
	return false
