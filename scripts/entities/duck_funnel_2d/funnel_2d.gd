extends StaticBody2D

## Funnel body. Collision on this node itself only covers the two slanted
## side walls (added as child CollisionShape2D/CollisionPolygon2D nodes in
## the scene) so feathers slide down into the center. The "Gate" child node
## holds the bottom collision shape which starts closed (enabled) so the
## initial batch of feathers rests inside the funnel until a duck arrives.

signal gate_opened
signal gate_closed

@onready var gate_collision: CollisionShape2D = $Gate/CollisionShape2D
@onready var gate_visual: Polygon2D = $Gate/GateVisual

var is_open: bool = false
var _current_duck: Node = null


func _ready() -> void:
	_set_gate_open(false)


## Called by a duck once it stops under the funnel. Only one duck is fed at
## a time.
func request_feed(duck: Node) -> void:
	if _current_duck != null:
		return
	_current_duck = duck
	_set_gate_open(true)


## Called by a duck once its pillowcase is full (or it gives up waiting).
func release_feed(duck: Node) -> void:
	if _current_duck != duck:
		return
	_current_duck = null
	_set_gate_open(false)


func _set_gate_open(open: bool) -> void:
	is_open = open
	gate_collision.set_deferred("disabled", open)
	if gate_visual:
		gate_visual.visible = not open
	if open:
		_wake_resting_feathers()
		gate_opened.emit()
	else:
		gate_closed.emit()


## Sleeping RigidBody2D feathers resting on the gate won't fall on their own
## just because the gate's collision was disabled, so explicitly wake them.
func _wake_resting_feathers() -> void:
	for feather in get_tree().get_nodes_in_group("feather"):
		if feather is RigidBody2D:
			feather.sleeping = false
