extends Area3D

## Scene instantiated for each spawned feather.
@export var feather_scene: PackedScene
## Node that spawned feathers are parented to. If left unset, the spawner uses
## the node in the "feather_container" group, falling back to its own parent.
@export var feather_container: Node3D
## Shortest delay (seconds) between spawns.
@export var min_spawn_interval: float = 0.5
## Longest delay (seconds) between spawns.
@export var max_spawn_interval: float = 2.0
@export var spawner_size: float = 10.0

@onready var spawner_shape: CollisionShape3D = $spawnerShape

var _spawn_timer: Timer

var rng = RandomNumberGenerator.new()
var feather_types: Array = [] 
## Spawn weight for each entry in feather_types, in the same order. New feather
## types are only added to the active pool as the "Level Up" skill (id "2")
## is leveled up; see _get_active_weights().
var feather_weights: Array[float] = [0.5, 0.3, 0.2]

func _ready() -> void:
	feather_types.append(load("res://scenes/entities/feather/feather_0.tscn"))
	feather_types.append(load("res://scenes/entities/feather/feather_1.tscn"))
	feather_types.append(load("res://scenes/entities/feather/feather_2.tscn"))

	if feather_container == null:
		feather_container = get_parent().get_node("Feathers") as Node3D

	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = true
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)
	_schedule_next_spawn()

	spawner_shape.shape.size.x = spawner_size
	spawner_shape.shape.size.z = spawner_size


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

	print("feather spawned")

	var half := box.size * 0.5
	var local_pos := spawner_shape.transform * Vector3(
		randf_range(-half.x, half.x),
		randf_range(-half.y, half.y),
		randf_range(-half.z, half.z)
	)

	# var feather := feather_scene.instantiate() as Node3D
	# var weights := PackedFloat32Array()
	# weights.append_array([0.5, 0.3, 0.2])
	var feather_index = rng.rand_weighted(_get_active_weights())
	var feather := feather_types[feather_index].instantiate() as Node3D
	feather_container.add_child(feather)
	feather.global_position = to_global(local_pos)


## Only feather types unlocked so far by the "Level Up" skill (id "2") can be
## spawned. Level 0 -> just feather_types[0], level 1 -> feather_types[0..1],
## etc. Returns their weights, sliced from feather_weights in the same order.
func _get_active_weights() -> Array[float]:
	var unlocked_count: int = clampi(SkillTreeManager.get_level("2") + 1, 1, feather_types.size())
	return feather_weights.slice(0, unlocked_count)
