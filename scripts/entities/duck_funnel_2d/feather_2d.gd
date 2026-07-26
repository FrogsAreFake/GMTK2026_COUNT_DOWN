extends RigidBody2D

## Small physics-driven feather. It falls under gravity, slides down the
## funnel's slanted side walls, and rests on the funnel's gate until the
## gate opens, at which point it falls through into a duck's pillowcase.


func _ready() -> void:
	add_to_group("feather")
