extends Node3D

## Drives the main gameplay round: counts down GameManager.get_round_duration(),
## then stops the round and shows a results popup with a button to continue
## to the shop. The shop itself is a persistent autoload (see project.godot)
## that keeps running in the background at all times, so "continuing" just
## reveals it as an overlay rather than changing scenes.

@onready var round_timer: Timer = $RoundTimer
@onready var timer_label: Label = $HUD/TimerPanel/TimerMargin/TimerLabel
@onready var results_popup: Control = $HUD/ResultsPopup
@onready var feathers_label: Label = %FeathersLabel
@onready var continue_button: Button = %ContinueButton
@onready var feather_spawner: Node = $featherSpawner
@onready var duck: Node = $Player
@onready var tier0_count_label: Label = %Tier0CountLabel
@onready var tier1_count_label: Label = %Tier1CountLabel
@onready var tier2_count_label: Label = %Tier2CountLabel
@onready var volume_slider: HSlider = %VolumeSlider


func _ready() -> void:
	results_popup.hide()
	continue_button.pressed.connect(_on_continue_pressed)
	round_timer.wait_time = GameManager.get_round_duration()
	round_timer.one_shot = true
	round_timer.timeout.connect(_on_round_timer_timeout)
	round_timer.start()
	_update_timer_label(round_timer.wait_time)
	GameManager.feathers_by_type_changed.connect(_on_feathers_by_type_changed)
	_update_feather_info_panel(GameManager.feathers_by_type)
	SoundManager.play_game_music()
	volume_slider.value = SoundManager.volume
	volume_slider.value_changed.connect(SoundManager.set_volume)
	SoundManager.volume_changed.connect(volume_slider.set_value_no_signal)


func _process(_delta: float) -> void:
	if not round_timer.is_stopped():
		_update_timer_label(round_timer.time_left)


func _update_timer_label(time_left: float) -> void:
	timer_label.text = "%d" % ceili(time_left)


## Refreshes the top-left "feathers caught this run" icon rows.
func _update_feather_info_panel(counts: Dictionary) -> void:
	tier0_count_label.text = "x%d" % counts.get(GameManager.FEATHER_TIER_COMMON, 0)
	tier1_count_label.text = "x%d" % counts.get(GameManager.FEATHER_TIER_UNCOMMON, 0)
	tier2_count_label.text = "x%d" % counts.get(GameManager.FEATHER_TIER_RARE, 0)


func _on_feathers_by_type_changed(counts: Dictionary) -> void:
	_update_feather_info_panel(counts)


func _on_round_timer_timeout() -> void:
	if is_instance_valid(feather_spawner):
		feather_spawner.queue_free()
	if is_instance_valid(duck):
		duck.set_process(false)
	timer_label.text = "0"
	feathers_label.text = "Feathers caught: %d" % GameManager.feathers_caught
	results_popup.show()


func _on_continue_pressed() -> void:
	SoundManager.play_button_pop()
	results_popup.hide()
	Shop.open()

