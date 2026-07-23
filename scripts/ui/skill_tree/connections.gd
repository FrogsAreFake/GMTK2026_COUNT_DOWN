class_name SkillConnections
extends Control

## Draws the lines that connect each skill to its prerequisites. Sits behind
## the skill nodes in the scene tree so the lines render underneath them.

const LINE_LOCKED := Color(0.3, 0.31, 0.38)
const LINE_UNLOCKED := Color(0.51, 0.92, 0.6)

var _skills: Array[SkillNode] = []


func setup(skills: Array[SkillNode]) -> void:
	_skills = skills
	queue_redraw()


func _draw() -> void:
	# Control has no to_local() (that is a Node2D method), so use the
	# CanvasItem transform to convert global centers into local draw space.
	var to_local_xform := get_global_transform().affine_inverse()
	for skill in _skills:
		for pre_path in skill.prerequisites:
			var pre := skill.get_node_or_null(pre_path) as SkillNode
			if pre == null:
				continue
			var from := to_local_xform * pre.get_center()
			var to := to_local_xform * skill.get_center()
			var active: bool = pre.is_unlocked() and skill.is_unlocked()
			var color := LINE_UNLOCKED if active else LINE_LOCKED
			var width := 5.0 if active else 3.0
			draw_line(from, to, color, width, true)
