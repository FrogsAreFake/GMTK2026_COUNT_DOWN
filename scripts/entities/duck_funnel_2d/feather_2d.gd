extends RigidBody2D

## Small physics-driven feather. It falls under gravity, slides down the
## funnel's slanted side walls, and rests on the funnel's gate until the
## gate opens, at which point it falls through into a duck's pillowcase.
## There is no floor in the shop scene, so any feather that isn't caught
## (missed the duck's catcher) would otherwise fall forever; instead, once it
## falls past despawn_y it's teleported back above the funnel to fall again
## rather than being lost, since it still represents a feather the player
## caught and is owed a payout for.

## Reward tier (see GameManager.FEATHER_TIER_*). Determines which feather
## PNG icon is shown and how much bonus money this feather is worth when
## its duck's pillow is sold.
@export var tier: int = 0
## World-space Y position past which this feather is considered "missed"
## (fell through without being caught by a duck) and gets teleported back
## above the funnel to try again, since there's no floor to stop it.
@export var despawn_y: float = 640.0
## Horizontal jitter applied when teleporting a missed feather back above
## the funnel, so recycled feathers don't all stack in the same spot.
@export var respawn_area_width: float = 60.0
## How far above respawn_origin a recycled feather reappears, plus a small
## random amount, so it has to fall back down through the funnel again.
@export var respawn_height: float = 40.0
@export var respawn_height_variance: float = 30.0

const TIER_TEXTURES := {
	0: preload("res://assets/textures/feather_5.png"),
	1: preload("res://assets/textures/feather_0.png"),
	2: preload("res://assets/textures/feather_2.png"),
}

@onready var sprite: Sprite2D = $Sprite2D

## World position to teleport back to (above the funnel) when this feather
## falls past despawn_y without being caught. Set by whatever spawns this
## feather (see initial_feather_spawner_2d.gd's set_respawn_origin call);
## falls back to this feather's own starting position if never set.
var respawn_origin: Vector2 = Vector2.ZERO
var _respawn_origin_set: bool = false


func _ready() -> void:
	add_to_group("feather")
	set_tier(tier)
	if not _respawn_origin_set:
		respawn_origin = global_position


func _process(_delta: float) -> void:
	if global_position.y > despawn_y:
		_respawn_above_funnel()


## Sets the reward tier and updates the sprite to the matching feather PNG.
func set_tier(new_tier: int) -> void:
	tier = new_tier
	if sprite and TIER_TEXTURES.has(tier):
		sprite.texture = TIER_TEXTURES[tier]


## Called by the spawner right after instantiation so a missed feather knows
## where "above the funnel" is when it needs to be teleported back.
func set_respawn_origin(pos: Vector2) -> void:
	respawn_origin = pos
	_respawn_origin_set = true


## Teleports this feather back above the funnel and resets its physics state
## so it falls fresh, instead of despawning a feather the player already
## caught (and is owed a payout for) just because a duck missed it.
func _respawn_above_funnel() -> void:
	global_position = respawn_origin + Vector2(
		randf_range(-respawn_area_width * 0.5, respawn_area_width * 0.5),
		-respawn_height - randf_range(0.0, respawn_height_variance)
	)
	rotation = randf_range(0.0, TAU)
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	sleeping = false
