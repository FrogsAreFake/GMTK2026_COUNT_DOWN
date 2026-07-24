extends Node
 
## Autoload this as "SkillTreePanState".
## Shared between SkillTreeView (which pans) and SkillNodeButton (which buys),
## so a drag that happens to start on top of a button doesn't fire a purchase.
 
var dragging: bool = false
var drag_threshold: float = 8.0 # pixels of movement before it counts as a drag, not a click
var press_start: Vector2 = Vector2.ZERO
var moved_beyond_threshold: bool = false
 
func begin_press(global_pos: Vector2) -> void:
	dragging = true
	press_start = global_pos
	moved_beyond_threshold = false
 
func update_press(global_pos: Vector2) -> void:
	if dragging and press_start.distance_to(global_pos) > drag_threshold:
		moved_beyond_threshold = true
 
func end_press() -> void:
	dragging = false
 
