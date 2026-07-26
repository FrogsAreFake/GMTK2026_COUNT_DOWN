extends Node

## Autoload "SoundManager": lets any script trigger a one-shot sound effect
## without needing a dedicated AudioStreamPlayer node wired into every scene.
## Each call spawns a short-lived AudioStreamPlayer that frees itself once the
## clip finishes playing.

const BUTTON_POP: AudioStream = preload("res://assets/audio/button_pop.wav")
const COIN: AudioStream = preload("res://assets/audio/coin.wav")


## Plays for every button/skill-node click across the game's UI.
func play_button_pop() -> void:
	_play(BUTTON_POP)


## Plays whenever the player catches a feather.
func play_coin() -> void:
	_play(COIN)


func _play(stream: AudioStream) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
