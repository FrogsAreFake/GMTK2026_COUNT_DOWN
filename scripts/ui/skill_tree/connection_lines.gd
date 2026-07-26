extends Control
class_name ConnectionLines

## Lives inside "World" (see skill_tree_view.gd) so it pans/zooms with the nodes.
## Set mouse_filter = Ignore on this node in the editor so it never blocks clicks.

var view: SkillTreeView # assigned by SkillTreeView on _ready

func _draw() -> void:
	if view != null:
		view.draw_connections(self)
