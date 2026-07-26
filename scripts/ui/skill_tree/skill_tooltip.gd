extends PanelContainer
class_name SkillTooltip

## Attach to a PanelContainer scene (SkillTooltip.tscn) with children:
##   Margin (MarginContainer)
##     HBox (HBoxContainer)
##       IconContainer (AspectRatioContainer, ratio 1:1, square, fills the tooltip height)
##         Icon        (TextureRect)
##       Info (VBoxContainer)
##         Title       (Label)
##         Description (Label, autowrap on, faded)
##         Status      (Label)
##       CostMargin (MarginContainer, right margin for proportional spacing from the edge)
##         CostLabel  (Label, large text, right-aligned)

@onready var icon_rect: TextureRect = $Margin/HBox/IconContainer/Icon
@onready var title_label: Label = $Margin/HBox/Info/Title
@onready var desc_label: Label = $Margin/HBox/Info/Description
@onready var status_label: Label = $Margin/HBox/Info/Status
@onready var cost_label: Label = $Margin/HBox/CostMargin/CostLabel

func show_for(skill: SkillData, level: int, next_cost: int) -> void:
	icon_rect.texture = skill.icon
	title_label.text = skill.display_name
	desc_label.text = skill.description

	var status := ""
	if skill.max_level > 1:
		status = "Level %d / %d" % [level, skill.max_level]
	else:
		status = "Unlocked" if level > 0 else "Locked"
	status_label.text = status

	if next_cost >= 0:
		cost_label.text = "$%d" % next_cost
	else:
		cost_label.text = "Maxed"

	show()

