# REGULAR FEATHER

extends Feather

@export var fall_speed: float = 0.01
@export var float_range: float = 0.5
@export var min_speed: float = 0.01
@export var max_speed: float = 0.01

var speed = min_speed
var direction = Vector2(1, 0)
var x = 0.0
var d = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	# Determine axis of movement
	direction = direction.rotated(randf_range(0, PI))
	x = randf_range(-float_range, float_range)
	speed = randf_range(min_speed, max_speed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super(delta)

	if(active == true):
		if(x >= float_range || x <= -float_range):
			direction = -direction
			d = -d

		x += speed * d
		# x += speed
		self.position += speed * Vector3(
			direction.x, 
			0, 
			direction.y
		) * -((x/float_range)**2 - 1)
		
		self.position.y -= fall_speed
