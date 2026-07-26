extends Node2D

## Periodically spawns ducks so the line always looks indefinite. Each new
## duck is linked to the previously spawned duck ("duck_ahead") so the line
## self-organizes without a central queue manager: a duck only advances if
## it isn't too close to the duck ahead of it.

@export var duck_scene: PackedScene
@export var min_spawn_interval: float = 2.0
@export var max_spawn_interval: float = 3.5
## Money earned each time a duck's pillowcase is filled and sold.
@export var money_per_pillow: int = 20
## Node the spawned ducks are parented to. Falls back to this spawner's
## parent if left unset.
@export var duck_container_path: NodePath
@export var duck_stop_marker_path: NodePath
@export var funnel_path: NodePath

var duck_container: Node = null
var duck_stop_marker: Node2D = null
var funnel: Node = null

var _last_duck: Node2D = null
var _spawn_timer: Timer


func _ready() -> void:
	duck_container = get_node_or_null(duck_container_path)
	if duck_container == null:
		duck_container = get_parent()
	duck_stop_marker = get_node_or_null(duck_stop_marker_path)
	funnel = get_node_or_null(funnel_path)

	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = true
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)

	_spawn()
	_schedule_next_spawn()


func _schedule_next_spawn() -> void:
	_spawn_timer.start(randf_range(min_spawn_interval, max_spawn_interval))


func _on_spawn_timer_timeout() -> void:
	_spawn()
	_schedule_next_spawn()


func _spawn() -> void:
	if duck_scene == null or duck_container == null:
		return

	var duck := duck_scene.instantiate() as Node2D
	duck_container.add_child(duck)
	duck.global_position = global_position
	duck.duck_ahead = _last_duck
	duck.funnel = funnel
	if duck_stop_marker:
		duck.stop_x = duck_stop_marker.global_position.x
	duck.pillowcase_filled.connect(_on_pillowcase_filled)

	_last_duck = duck


## A duck's pillowcase reached capacity — sell the pillow for money.
func _on_pillowcase_filled(_duck: Node2D) -> void:
	GameManager.add_money(money_per_pillow)
