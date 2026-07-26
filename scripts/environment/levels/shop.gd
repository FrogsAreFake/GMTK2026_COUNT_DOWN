extends Node2D

## Root script for the shop. This scene is a persistent autoload (see
## project.godot) so the duck/funnel simulation keeps running in real time no
## matter which scene is currently active, including while the player is
## still playing a round in Main. Feathers only appear in the funnel once a
## run ends: open() drops that run's catch in as a single batch. The shop's
## visuals and UI are hidden by default and only revealed via open()/close()
## so it can be shown as a full-screen overlay once a round ends.

@onready var world: CanvasLayer = $World
@onready var ui: CanvasLayer = $UI
@onready var initial_feather_spawner: Node2D = $World/InitialFeatherSpawner
@onready var money_label: Label = %MoneyLabel
@onready var feathers_label: Label = %FeathersLabel
@onready var upgrades_button: Button = $UI/BottomBar/UpgradesButton
@onready var play_again_button: Button = $UI/BottomBar/PlayAgainButton
@onready var upgrades_popup: Control = $UI/UpgradesPopup
@onready var close_button: Button = $UI/UpgradesPopup/CloseButton
@onready var volume_slider: HSlider = %VolumeSlider


func _ready() -> void:
	world.visible = false
	ui.visible = false
	upgrades_popup.hide()

	upgrades_button.pressed.connect(_on_upgrades_pressed)
	close_button.pressed.connect(_on_close_pressed)
	play_again_button.pressed.connect(_on_play_again_pressed)
	volume_slider.value = SoundManager.volume
	volume_slider.value_changed.connect(SoundManager.set_volume)
	SoundManager.volume_changed.connect(volume_slider.set_value_no_signal)

	GameManager.money_changed.connect(_on_money_changed)
	GameManager.feathers_caught_changed.connect(_on_feathers_caught_changed)
	_update_stats()


## Reveals the shop as a full-screen overlay and drops the feathers caught
## during the run that just ended into the funnel. The duck/funnel simulation
## itself never stops (it runs whether or not this is visible) — only the
## feathers from this run are added at this point.
func open() -> void:
	initial_feather_spawner.spawn_feathers(GameManager.feathers_by_type)
	world.visible = true
	ui.visible = true
	SoundManager.play_menu_music()


## Hides the shop's visuals/UI again. The duck/funnel simulation keeps
## running in the background regardless.
func close() -> void:
	upgrades_popup.hide()
	world.visible = false
	ui.visible = false


func _update_stats() -> void:
	money_label.text = "Money: %d" % GameManager.money
	feathers_label.text = "Feathers this run: %d" % GameManager.feathers_caught


func _on_money_changed(_new_amount: int) -> void:
	_update_stats()


func _on_feathers_caught_changed(_new_amount: int) -> void:
	_update_stats()


func _on_upgrades_pressed() -> void:
	SoundManager.play_button_pop()
	upgrades_popup.show()


func _on_close_pressed() -> void:
	SoundManager.play_button_pop()
	upgrades_popup.hide()


func _on_play_again_pressed() -> void:
	SoundManager.play_button_pop()
	close()
	GameManager.start_new_run()
