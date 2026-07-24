extends Node

## Autoload this as "SkillTreeManager".
## Owns currency + which level every skill is at, and the purchase rules.

signal currency_changed(new_amount: int)
signal skill_purchased(skill_id: String, new_level: int)

var currency: int = 500
var skill_levels: Dictionary = {} # skill_id (String) -> level (int)

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
	currency -= cost
	skill_levels[skill.id] = get_level(skill.id) + 1
	currency_changed.emit(currency)
	skill_purchased.emit(skill.id, skill_levels[skill.id])
	return true

func add_currency(amount: int) -> void:
	currency += amount
	currency_changed.emit(currency)

## --- Optional persistence helpers ---

func to_save_dict() -> Dictionary:
	return {"currency": currency, "levels": skill_levels}

func load_from_dict(data: Dictionary) -> void:
	currency = data.get("currency", currency)
	skill_levels = data.get("levels", {})
	currency_changed.emit(currency)
