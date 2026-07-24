extends TextureButton
class_name SkillNodeButton

## Attach to a TextureButton scene (SkillNode.tscn) with children:
##   Icon        (TextureRect)
##   LevelLabel  (Label)   -- shows "2/4", hidden for one-shot unlocks
##   LockIcon    (Control) -- any visual for "locked", shown/hidden automatically

signal hovered(skill: SkillData, screen_pos: Vector2)
signal unhovered
signal purchase_attempted(skill: SkillData)

@export var locked_modulate: Color = Color(0.4, 0.4, 0.4, 1.0)
@export var maxed_modulate: Color = Color(1.0, 0.85, 0.3, 1.0)
@export var owned_modulate: Color = Color.WHITE
@export var available_modulate: Color = Color(0.85, 0.85, 0.85, 1.0)

var skill_data: SkillData

@onready var level_label: Label = $LevelLabel
@onready var icon_rect: TextureRect = $Icon
@onready var lock_icon: Control = $LockIcon

func setup(data: SkillData) -> void:
	skill_data = data
	icon_rect.texture = data.icon
	SkillTreeManager.skill_purchased.connect(_on_skill_purchased)
	SkillTreeManager.currency_changed.connect(_on_currency_changed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	refresh()

func _on_skill_purchased(_id: String, _new_level: int) -> void:
	refresh()

func _on_currency_changed(_new_amount: int) -> void:
	refresh()

func refresh() -> void:
	if skill_data == null:
		return
	var level := SkillTreeManager.get_level(skill_data.id)
	var unlocked := SkillTreeManager.is_unlocked(skill_data)
	var maxed := SkillTreeManager.is_maxed(skill_data)

	if skill_data.max_level > 1:
		level_label.text = "%d/%d" % [level, skill_data.max_level]
		level_label.visible = true
	else:
		level_label.visible = false

	lock_icon.visible = not unlocked and level == 0
	disabled = not unlocked

	if maxed:
		modulate = maxed_modulate
	elif not unlocked:
		modulate = locked_modulate
	elif level > 0:
		modulate = owned_modulate
	else:
		modulate = available_modulate

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			SkillTreePanState.begin_press(get_global_mouse_position())
		else:
			# Only treat this as a purchase click if the mouse never left drag threshold.
			if not SkillTreePanState.moved_beyond_threshold:
				purchase_attempted.emit(skill_data)
			SkillTreePanState.end_press()

func _on_mouse_entered() -> void:
	hovered.emit(skill_data, get_global_mouse_position())

func _on_mouse_exited() -> void:
	unhovered.emit()
