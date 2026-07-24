extends PanelContainer
class_name SkillTooltip

## Attach to a PanelContainer scene (SkillTooltip.tscn) with children:
##   Margin (MarginContainer)
##     VBox (VBoxContainer)
##       Title       (Label)
##       Description (Label, autowrap on)
##       Status      (Label)

@onready var title_label: Label = $Margin/VBox/Title
@onready var desc_label: Label = $Margin/VBox/Description
@onready var status_label: Label = $Margin/VBox/Status

func show_for(skill: SkillData, level: int, next_cost: int) -> void:
	title_label.text = skill.display_name
	desc_label.text = skill.description

	var status := ""
	if skill.max_level > 1:
		status = "Level %d / %d" % [level, skill.max_level]
	else:
		status = "Unlocked" if level > 0 else "Locked"

	if next_cost >= 0:
		status += "   •   Cost: %d" % next_cost
	else:
		status += "   •   Maxed"

	status_label.text = status
	show()
