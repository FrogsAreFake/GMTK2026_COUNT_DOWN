extends Resource
class_name SkillData

## One skill in the tree. Create these as .tres resources, one per skill.

@export var id: String = ""                      ## Unique key, e.g. "fire_bolt"
@export var display_name: String = "Skill"
@export var description: String = ""
@export var icon: Texture2D

## Where this node sits on the grid, in cell units (not pixels). (0,0) is the tree's origin.
@export var grid_position: Vector2i = Vector2i.ZERO

## 1 = simple unlock (buy once). >1 = upgradeable that many times.
@export var max_level: int = 1

## Cost for each level. Size should equal max_level.
## costs[0] = cost to go from level 0 -> 1, costs[1] = level 1 -> 2, etc.
@export var costs: Array[int] = [100]

## Skill ids that must be at level >= 1 before this one can be purchased at all.
@export var prerequisite_ids: Array[String] = []
