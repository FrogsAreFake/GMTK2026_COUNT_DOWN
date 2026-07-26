extends RigidBody2D

## Small physics-driven feather. It falls under gravity, slides down the
## funnel's slanted side walls, and rests on the funnel's gate until the
## gate opens, at which point it falls through into a duck's pillowcase.

## Reward tier (see GameManager.FEATHER_TIER_*). Determines which feather
## PNG icon is shown and how much bonus money this feather is worth when
## its duck's pillow is sold.
@export var tier: int = 0

const TIER_TEXTURES := {
	0: preload("res://assets/textures/feather_5.png"),
	1: preload("res://assets/textures/feather_0.png"),
	2: preload("res://assets/textures/feather_2.png"),
}

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("feather")
	set_tier(tier)


## Sets the reward tier and updates the sprite to the matching feather PNG.
func set_tier(new_tier: int) -> void:
	tier = new_tier
	if sprite and TIER_TEXTURES.has(tier):
		sprite.texture = TIER_TEXTURES[tier]
