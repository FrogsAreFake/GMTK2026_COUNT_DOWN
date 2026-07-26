extends Node

## Autoload "SoundManager": lets any script trigger a one-shot sound effect
## without needing a dedicated AudioStreamPlayer node wired into every scene.
## Each call spawns a short-lived AudioStreamPlayer that frees itself once the
## clip finishes playing. Also manages looping background music via a single
## shared AudioStreamPlayer (see play_menu_music()/play_game_music()). Both
## music and one-shot sound effects are routed through the Master audio bus,
## whose volume is globally adjustable (see set_volume()).

signal volume_changed(new_volume: float)

const BUTTON_POP: AudioStream = preload("res://assets/audio/button_pop.wav")
const COIN: AudioStream = preload("res://assets/audio/coin.wav")
const MENU_MUSIC: AudioStream = preload("res://assets/audio/menu_music.mp3")
const GAME_MUSIC: AudioStream = preload("res://assets/audio/game_music.mp3")

const MASTER_BUS := "Master"

## Linear volume (0.0-1.0) applied to the Master bus, so it affects music and
## sound effects alike. Defaults to 50% so audio doesn't overpower on launch.
var volume: float = 0.5:
	set(value):
		volume = clampf(value, 0.0, 1.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MASTER_BUS), linear_to_db(volume))
		volume_changed.emit(volume)

## Single looping player reused for background music so switching tracks
## (e.g. menu <-> game) doesn't stack overlapping AudioStreamPlayers.
@onready var _music_player: AudioStreamPlayer = _make_music_player()


## Plays for every button/skill-node click across the game's UI.
func play_button_pop() -> void:
	_play(BUTTON_POP)


## Plays whenever the player catches a feather.
func play_coin() -> void:
	_play(COIN)


## Loops the menu/shop background track. Used for the main menu and the shop.
func play_menu_music() -> void:
	_play_music(MENU_MUSIC)


## Loops the gameplay background track. Used while a round is in progress.
func play_game_music() -> void:
	_play_music(GAME_MUSIC)


## Sets the overall game volume (0.0-1.0), applied to music and sound effects
## alike via the Master bus. Called by the volume slider shown alongside the
## run/shop stats.
func set_volume(value: float) -> void:
	volume = value


func _make_music_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	add_child(player)
	return player


func _play_music(stream: AudioStream) -> void:
	if _music_player.stream == stream and _music_player.playing:
		return
	if "loop" in stream:
		stream.loop = true
	_music_player.stream = stream
	_music_player.play()


func _play(stream: AudioStream) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
