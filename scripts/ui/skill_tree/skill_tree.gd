extends Control

## Controller for the skill tree page. Collects every SkillNode under the
## "SkillNodes" container, manages skill points, unlock logic and the info
## panel, and keeps the connection lines in sync with the current state.

@export var starting_points: int = 5

var _skills: Array[SkillNode] = []
var _selected: SkillNode = null
var _points: int = 0

@onready var _connections: SkillConnections = $Connections
@onready var _points_label: Label = $HeaderPanel/HeaderMargin/PointsLabel
@onready var _info_name: Label = $InfoPanel/InfoMargin/InfoBox/TextBox/SkillName
@onready var _info_cost: Label = $InfoPanel/InfoMargin/InfoBox/TextBox/SkillCost
@onready var _info_desc: Label = $InfoPanel/InfoMargin/InfoBox/TextBox/SkillDescription
@onready var _unlock_button: Button = $InfoPanel/InfoMargin/InfoBox/UnlockButton


func _ready() -> void:
	_points = starting_points
	_collect_skills($SkillNodes)
	for s in _skills:
		s.skill_selected.connect(_on_skill_selected)
	for s in _skills:
		if s.unlocked_from_start:
			s.set_state(SkillNode.State.UNLOCKED)
	_unlock_button.pressed.connect(_on_unlock_pressed)
	_refresh_states()
	_update_points_label()
	_show_info(null)
	# Wait one frame so containers have finished laying out before we read
	# node centers to draw the connection lines.
	await get_tree().process_frame
	_connections.setup(_skills)


func _collect_skills(root: Node) -> void:
	for child in root.get_children():
		if child is SkillNode:
			_skills.append(child as SkillNode)


func _on_skill_selected(skill: SkillNode) -> void:
	_selected = skill
	skill.grab_focus()
	_show_info(skill)


func _on_unlock_pressed() -> void:
	if _selected == null:
		return
	if _selected.state != SkillNode.State.AVAILABLE:
		return
	if _points < _selected.cost:
		return
	_points -= _selected.cost
	_selected.set_state(SkillNode.State.UNLOCKED)
	_refresh_states()
	_update_points_label()
	_show_info(_selected)


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
		_info_name.text = "Select a skill"
		_info_cost.text = ""
		_info_desc.text = "Click an available skill node to see details and unlock it."
		_unlock_button.disabled = true
		_unlock_button.text = "Unlock"
		return

	_info_name.text = skill.skill_name
	_info_cost.text = "Cost: %d point(s)" % skill.cost
	_info_desc.text = skill.description

	match skill.state:
		SkillNode.State.UNLOCKED:
			_unlock_button.disabled = true
			_unlock_button.text = "Unlocked"
		SkillNode.State.AVAILABLE:
			var affordable := _points >= skill.cost
			_unlock_button.disabled = not affordable
			_unlock_button.text = "Unlock" if affordable else "Not enough points"
		SkillNode.State.LOCKED:
			_unlock_button.disabled = true
			_unlock_button.text = "Locked"
