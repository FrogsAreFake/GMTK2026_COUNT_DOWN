extends Node2D

## Spawns the initial batch of feathers above the funnel when the scene
## starts. They fall under gravity, slide down the funnel's side walls, and
## come to rest on the closed gate until a duck arrives.

@export var feather_scene: PackedScene
@export var count: int = 10
@export var spawn_area_width: float = 90.0
@export var spawn_height_variance: float = 60.0
@export var vertical_spacing: float = 18.0
## Node the spawned feathers are parented to. Falls back to this spawner's
## parent if left unset.
@export var feather_container_path: NodePath

var feather_container: Node = null


func _ready() -> void:
	feather_container = get_node_or_null(feather_container_path)
	if feather_container == null:
		feather_container = get_parent()
	if feather_scene == null or feather_container == null:
		return

	for i in range(count):
		var feather := feather_scene.instantiate() as Node2D
		feather_container.add_child(feather)
		feather.global_position = global_position + Vector2(
			randf_range(-spawn_area_width * 0.5, spawn_area_width * 0.5),
			-randf_range(0.0, spawn_height_variance) - i * vertical_spacing
		)
