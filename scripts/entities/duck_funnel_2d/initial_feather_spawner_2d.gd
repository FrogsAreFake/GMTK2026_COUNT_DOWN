extends Node2D

## Spawns feathers above the funnel. They fall under gravity, slide down the
## funnel's side walls, and come to rest on the closed gate until a duck
## arrives. The shop calls `spawn_feathers()` once per run, as a batch, when
## the player returns to the shop after a round ends.

@export var feather_scene: PackedScene
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


## Spawns feathers above the funnel, using the counts caught per tier this
## run (see GameManager.feathers_by_type) so the shop-dropped feathers use
## the correct PNG per tier. `counts_by_tier` maps tier -> feather count.
func spawn_feathers(counts_by_tier: Dictionary) -> void:
	if feather_scene == null or feather_container == null:
		return

	var i := 0
	for tier in counts_by_tier.keys():
		var count: int = counts_by_tier[tier]
		for _n in range(count):
			var feather := feather_scene.instantiate() as Node2D
			if feather.has_method("set_tier"):
				feather.call("set_tier", tier)
			feather_container.add_child(feather)
			feather.global_position = global_position + Vector2(
				randf_range(-spawn_area_width * 0.5, spawn_area_width * 0.5),
				-randf_range(0.0, spawn_height_variance) - i * vertical_spacing
			)
			feather.rotation = randf_range(0.0, TAU)
			if feather.has_method("set_respawn_origin"):
				feather.call("set_respawn_origin", global_position)
			i += 1
