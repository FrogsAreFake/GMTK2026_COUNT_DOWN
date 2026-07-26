extends Node

## Owns run/meta state shared across scenes: money (persists across runs),
## feathers caught (reset every run), and the round countdown length.

signal money_changed(new_amount: int)
signal feathers_caught_changed(new_amount: int)
signal feathers_by_type_changed(counts: Dictionary)

const MAIN_SCENE := "res://scenes/core/main.tscn"

## Feather tiers, in ascending order of rarity/value. Matches the spawn
## weights in feather_spawner.gd (0=common/50%, 1=uncommon/30%, 2=rare/20%)
## and the tier exported on each feather_#.tscn scene.
const FEATHER_TIER_COMMON := 0
const FEATHER_TIER_UNCOMMON := 1
const FEATHER_TIER_RARE := 2

## Persists across runs (spent on upgrades, earned by selling pillows in the shop).
var money: int = 100
## Reset every run: total feathers the player caught during the current round.
var feathers_caught: int = 0
## Reset every run: feathers caught this round, keyed by tier (see FEATHER_TIER_* above).
var feathers_by_type: Dictionary = {
	FEATHER_TIER_COMMON: 0,
	FEATHER_TIER_UNCOMMON: 0,
	FEATHER_TIER_RARE: 0,
}
## Length, in seconds, of the main scene's countdown before the Overtime skill's bonus.
var round_duration: float = 50.0
## Added to round_duration per level of the Overtime skill (id "5") purchased.
var overtime_seconds_per_level: float = 3.0


func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)


func catch_feather(tier: int = FEATHER_TIER_COMMON) -> void:
	feathers_caught += 1
	feathers_by_type[tier] = feathers_by_type.get(tier, 0) + 1
	feathers_caught_changed.emit(feathers_caught)
	feathers_by_type_changed.emit(feathers_by_type)


## Length of the round countdown, including any bonus seconds from the
## Overtime skill ("work longer shifts for more pay").
func get_round_duration() -> float:
	return round_duration + SkillTreeManager.get_level("5") * overtime_seconds_per_level


## Resets run-scoped state (feathers caught) and starts a fresh round in the
## main scene. Money and purchased upgrades are intentionally left untouched.
func start_new_run() -> void:
	feathers_caught = 0
	feathers_by_type = {
		FEATHER_TIER_COMMON: 0,
		FEATHER_TIER_UNCOMMON: 0,
		FEATHER_TIER_RARE: 0,
	}
	feathers_caught_changed.emit(feathers_caught)
	feathers_by_type_changed.emit(feathers_by_type)
	get_tree().change_scene_to_file(MAIN_SCENE)
