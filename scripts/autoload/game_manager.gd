extends Node

## Owns run/meta state shared across scenes: money (persists across runs),
## feathers caught (reset every run), and the round countdown length.

signal money_changed(new_amount: int)
signal feathers_caught_changed(new_amount: int)

const MAIN_SCENE := "res://scenes/core/main.tscn"

## Persists across runs (spent on upgrades, earned by selling pillows in the shop).
var money: int = 100
## Reset every run: how many feathers the player caught during the current round.
var feathers_caught: int = 0
## Length, in seconds, of the main scene's countdown before the Overtime skill's bonus.
var round_duration: float = 50.0
## Added to round_duration per level of the Overtime skill (id "5") purchased.
var overtime_seconds_per_level: float = 3.0


func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)


func catch_feather(value: int = 1) -> void:
	feathers_caught += value
	feathers_caught_changed.emit(feathers_caught)


## Length of the round countdown, including any bonus seconds from the
## Overtime skill ("work longer shifts for more pay").
func get_round_duration() -> float:
	return round_duration + SkillTreeManager.get_level("5") * overtime_seconds_per_level


## Resets run-scoped state (feathers caught) and starts a fresh round in the
## main scene. Money and purchased upgrades are intentionally left untouched.
func start_new_run() -> void:
	feathers_caught = 0
	feathers_caught_changed.emit(feathers_caught)
	get_tree().change_scene_to_file(MAIN_SCENE)
