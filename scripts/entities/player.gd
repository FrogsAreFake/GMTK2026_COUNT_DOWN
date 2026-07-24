extends Node

@export var mouse_sensitivity = 0.005
@export var speed = 0.01
@export var bounds_size = 2

var mouse_pos_zero = Vector2(0, 0)
var offset = Vector2(0, 0)
var player_start_pos = Vector3(0, 0, 0)
var mouse_held = false
var bound_offset = 0.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set the player radius based on the scale (mesh should be radius 1)
	bound_offset = self.scale.x / 2


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		if(!mouse_held): # Clicked
			mouse_pos_zero = get_viewport().get_mouse_position();
			mouse_held = true;
			player_start_pos = self.global_position
		

		offset = get_viewport().get_mouse_position() - mouse_pos_zero

		var target = Vector3(
			player_start_pos.x + (offset.x * mouse_sensitivity), 
			0,
			player_start_pos.z + (offset.y * mouse_sensitivity)
		).rotated(Vector3.UP, deg_to_rad(45)) # Rotated cause we're isometric

		var distance = self.global_position.distance_to(target)
		var direction = (target - self.global_position).normalized()

		self.global_position += direction * (distance + 0.1) * speed
		if(self.global_position.x > bounds_size - bound_offset):
			self.global_position.x = bounds_size - bound_offset
		elif(self.global_position.x < -bounds_size + bound_offset):
			self.global_position.x = -bounds_size + bound_offset

		if(self.global_position.z > bounds_size - bound_offset):
			self.global_position.z = bounds_size - bound_offset
		elif(self.global_position.z < -bounds_size + bound_offset):
			self.global_position.z = -bounds_size + bound_offset

	else:
		mouse_held = false;
