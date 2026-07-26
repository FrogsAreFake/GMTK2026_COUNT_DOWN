extends Node

## Autoload this as "SkillTreeManager".
## Owns which level every skill is at and the purchase rules. Currency itself
## lives on GameManager.money (money earned selling pillows funds upgrades);
## this just forwards it under the "currency" name for existing UI code.

signal currency_changed(new_amount: int)
signal skill_purchased(skill_id: String, new_level: int)

var skill_levels: Dictionary = {} # skill_id (String) -> level (int)

var currency: int:
	get: return GameManager.money
	set(value): GameManager.money = value


func _ready() -> void:
	GameManager.money_changed.connect(_on_money_changed)


func _on_money_changed(new_amount: int) -> void:
	currency_changed.emit(new_amount)

func get_level(id: String) -> int:
	return skill_levels.get(id, 0)

func is_unlocked(skill: SkillData) -> bool:
	for prereq_id in skill.prerequisite_ids:
		if get_level(prereq_id) <= 0:
			return false
	return true

func is_maxed(skill: SkillData) -> bool:
	return get_level(skill.id) >= skill.max_level

## Returns the cost of the *next* level, or -1 if already maxed.
func get_next_cost(skill: SkillData) -> int:
	var lvl := get_level(skill.id)
	if lvl >= skill.costs.size():
		return -1
	return skill.costs[lvl]

func can_purchase(skill: SkillData) -> bool:
	if is_maxed(skill):
		return false
	if not is_unlocked(skill):
		return false
	var cost := get_next_cost(skill)
	return cost >= 0 and currency >= cost

func purchase(skill: SkillData) -> bool:
	if not can_purchase(skill):
		return false
	var cost := get_next_cost(skill)
	GameManager.add_money(-cost)
	skill_levels[skill.id] = get_level(skill.id) + 1
	skill_purchased.emit(skill.id, skill_levels[skill.id])
	return true

func add_currency(amount: int) -> void:
	GameManager.add_money(amount)

## --- Optional persistence helpers ---

func to_save_dict() -> Dictionary:
	return {"currency": currency, "levels": skill_levels}

func load_from_dict(data: Dictionary) -> void:
	GameManager.money = data.get("currency", currency)
	skill_levels = data.get("levels", {})
	GameManager.money_changed.emit(GameManager.money)
