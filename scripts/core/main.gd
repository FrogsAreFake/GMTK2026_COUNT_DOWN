extends Node3D

## Drives the main gameplay round: counts down GameManager.get_round_duration(),
## then stops the round and shows a results popup with a button to continue
## to the shop. The shop itself is a persistent autoload (see project.godot)
## that keeps running in the background at all times, so "continuing" just
## reveals it as an overlay rather than changing scenes.

@onready var round_timer: Timer = $RoundTimer
@onready var timer_label: Label = $HUD/TimerLabel
@onready var results_popup: Control = $HUD/ResultsPopup
@onready var feathers_label: Label = %FeathersLabel
@onready var continue_button: Button = %ContinueButton
@onready var feather_spawner: Node = $featherSpawner
@onready var duck: Node = $Player


func _ready() -> void:
	results_popup.hide()
	continue_button.pressed.connect(_on_continue_pressed)
	round_timer.wait_time = GameManager.get_round_duration()
	round_timer.one_shot = true
	round_timer.timeout.connect(_on_round_timer_timeout)
	round_timer.start()
	_update_timer_label(round_timer.wait_time)


func _process(_delta: float) -> void:
	if not round_timer.is_stopped():
		_update_timer_label(round_timer.time_left)


func _update_timer_label(time_left: float) -> void:
	timer_label.text = "%d" % ceili(time_left)


func _on_round_timer_timeout() -> void:
	if is_instance_valid(feather_spawner):
		feather_spawner.queue_free()
	if is_instance_valid(duck):
		duck.set_process(false)
	timer_label.text = "0"
	feathers_label.text = "Feathers caught: %d" % GameManager.feathers_caught
	results_popup.show()


func _on_continue_pressed() -> void:
	results_popup.hide()
	Shop.open()

