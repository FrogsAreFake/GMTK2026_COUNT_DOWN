extends Node

@export_group("Gameplay Settings")
@export var speed: float = 0.01

@export_group("Editor Settings")
@export var fade_speed: float = 0.01
@export var active: bool = true


@onready var shadow = $Shadow
@onready var mesh = $FeatherModel


var material = StandardMaterial3D.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Setup for collision detection
	$Area3D.area_entered.connect(_on_area_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(self.position.y > 0): # Feather falling
		self.position.y -= speed
	elif(active == true): # Feather missed, it touched the ground
		active = false

		# tmp to tell that a feather is no longer active
		material.albedo_color = Color.RED
		mesh.set_surface_override_material(0, material)
		material.transparency = true;

	# When feather is no longer active, start fading intro transparency and eventually disappear
	if(active == false):
		material.albedo_color.a -= fade_speed
		if(material.albedo_color.a < 0):
			queue_free()
		

	# Set shadow to follow the feather
	shadow.global_position.x = self.global_position.x
	shadow.global_position.z = self.global_position.z
	shadow.global_position.y = 0


# Checking if feather is caught by the pillow
func _on_area_entered(area: Area3D):
	if(area.name == "PillowCollider" && self.active == true):
		print("Entered trigger!")
		queue_free()
