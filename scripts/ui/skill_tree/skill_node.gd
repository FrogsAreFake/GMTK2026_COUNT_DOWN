@tool
class_name SkillNode
extends Button

## A single node in the skill tree. Extends Button so it is clickable and
## focusable out of the box. Configure the exported fields per instance.

## Emitted when this node is clicked (only fires while it is not disabled).
signal skill_selected(skill: SkillNode)

enum State { LOCKED, AVAILABLE, UNLOCKED }

@export var skill_name: String = "Skill":
	set(value):
		skill_name = value
		_refresh_text()
@export_multiline var description: String = "A useful skill."
## How many skill points it costs to unlock.
@export var cost: int = 1
## NodePaths (relative to this node) to other SkillNodes that must be
## unlocked before this one becomes available.
@export var prerequisites: Array[NodePath] = []
## If true this skill starts already unlocked (use it for tree roots).
@export var unlocked_from_start: bool = false

const COLOR_LOCKED := Color(0.42, 0.43, 0.5)
const COLOR_AVAILABLE := Color(1.0, 0.93, 0.66)
const COLOR_UNLOCKED := Color(0.51, 0.92, 0.6)

var state: State = State.LOCKED


func _ready() -> void:
	custom_minimum_size = Vector2(150, 54)
	focus_mode = Control.FOCUS_ALL
	_refresh_text()
	if Engine.is_editor_hint():
		return
	pressed.connect(_on_pressed)
	set_state(State.LOCKED)


func set_state(new_state: State) -> void:
	state = new_state
	match state:
		State.LOCKED:
			modulate = COLOR_LOCKED
			disabled = true
		State.AVAILABLE:
			modulate = COLOR_AVAILABLE
			disabled = false
		State.UNLOCKED:
			modulate = COLOR_UNLOCKED
			disabled = false


func is_unlocked() -> bool:
	return state == State.UNLOCKED


## World-space center of the node, used to draw connection lines.
func get_center() -> Vector2:
	return global_position + size * 0.5


func _on_pressed() -> void:
	skill_selected.emit(self)


func _refresh_text() -> void:
	text = skill_name
