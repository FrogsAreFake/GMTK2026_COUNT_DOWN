extends Control

## Entry title screen shown when the game launches.
## The "Play" button starts the game by loading the gameplay scene.

const GAMEPLAY_SCENE := "res://scenes/core/main.tscn"

@onready var play_button: Button = %PlayButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_button_pressed)


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file(GAMEPLAY_SCENE)
