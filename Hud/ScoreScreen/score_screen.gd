extends CanvasLayer

@onready var title_label = $Panel/TitleLabel
@onready var kill_label = $Panel/KillLabel

func _ready():
	visible = false
	title_label.text = "ENNEMIS TUÉS"

func show_score(killed, total):
	kill_label.text = str(killed) + " / " + str(total)
	visible = true
