# PLAYER AVOIDING FEATHER

extends Feather

@export var fall_speed: float = 0.01
@export var float_range: float = 0.5
@export var min_speed: float = 0.1
@export var max_speed: float = 0.1
@export var rot_speed: float = 8.0

@onready var player = get_tree().get_first_node_in_group("player")

var speed = min_speed
var x = 0.0
var rot_dir = 1
var direction = Vector3(0, 0, 0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	# Determine axis of movement
	# direction = direction.rotated(randf_range(0, PI))
	x = randf_range(-float_range, float_range)
	rot_dir = randf_range(-1, 1)
	if(rot_dir > 0):
		rot_dir = 1
	else:
		rot_dir = -1
		
	speed = randf_range(min_speed, max_speed)
	self.rotation.y = randf_range(-90, 90)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super(delta)

	if(active == true && player != null):
		# x += speed * d
		x += speed * delta
		self.position += Vector3(
			speed * sin(x / float_range),
			0,
			speed * cos(x / float_range) * rot_dir,
		) * delta * fall_speed



		# self.rotation.y += speed * rot_speed * rot_dir * delta
		self.position.y -= (2 * sin(x) + 1) * delta 
