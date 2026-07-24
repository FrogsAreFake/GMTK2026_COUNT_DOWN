extends Area3D

## Scene instantiated for each spawned feather.
@export var feather_scene: PackedScene = preload("res://scenes/entities/feather/feather.tscn")
## Node that spawned feathers are parented to. If left unset, the spawner uses
## the node in the "feather_container" group, falling back to its own parent.
@export var feather_container: Node3D
## Shortest delay (seconds) between spawns.
@export var min_spawn_interval: float = 0.5
## Longest delay (seconds) between spawns.
@export var max_spawn_interval: float = 2.0

@onready var spawner_shape: CollisionShape3D = $spawnerShape

var _spawn_timer: Timer


func _ready() -> void:
	if feather_container == null:
		feather_container = get_parent().get_node("Feathers") as Node3D

	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = true
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)
	_schedule_next_spawn()


func _on_spawn_timer_timeout() -> void:
	spawn()
	_schedule_next_spawn()


func _schedule_next_spawn() -> void:
	_spawn_timer.start(randf_range(min_spawn_interval, max_spawn_interval))


func spawn() -> void:
	if feather_scene == null or feather_container == null:
		return
	var box := spawner_shape.shape as BoxShape3D
	if box == null:
		return

	var half := box.size * 0.5
	var local_pos := spawner_shape.transform * Vector3(
		randf_range(-half.x, half.x),
		randf_range(-half.y, half.y),
		randf_range(-half.z, half.z)
	)

	var feather := feather_scene.instantiate() as Node3D
	feather_container.add_child(feather)
	feather.global_position = to_global(local_pos)
