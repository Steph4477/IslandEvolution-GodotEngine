extends CanvasLayer

@onready var title_label = $Panel/TitleLabel
@onready var kill_label = $Panel/KillLabel
@onready var star_label = $Panel/StarLabel
@onready var medal_texture = $Panel2/MedalTexture

var bronze_medal = preload("res://Hud/ScoreScreen/Medals/medal_bronze.png")
var silver_medal = preload("res://Hud/ScoreScreen/Medals/medal_silver.png")
var gold_medal = preload("res://Hud/ScoreScreen/Medals/medal_gold.png")
var banana_medal = preload("res://Hud/ScoreScreen/Medals/medal_banana.png")

func _ready():
	visible = false
	title_label.text = "ENNEMIS TUÉS"


func show_score(killed, total, stars, medal):
	kill_label.text = str(killed) + " / " + str(total)

	if stars == 3:
		star_label.text = "⭐⭐⭐"
	elif stars == 2:
		star_label.text = "⭐⭐"
	elif stars == 1:
		star_label.text = "⭐"
	else:
		star_label.text = ""

	if medal == "gold":
		medal_texture.texture = gold_medal
	elif medal == "silver":
		medal_texture.texture = silver_medal
	elif medal == "bronze":
		medal_texture.texture = bronze_medal
	elif medal == "banana":
		medal_texture.texture = banana_medal
	else:
		medal_texture.texture = null

	visible = true
