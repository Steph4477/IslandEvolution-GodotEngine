extends CanvasLayer

@onready var level_name_label = $Panel3/LevelNameLabel
@onready var title_label = $Panel/EnemiesKillTitleLabel
@onready var kill_label = $Panel/KillLabel
@onready var level_mastery_title_label = $Panel/LevelMasteryTitleLabel
@onready var enemies_percentage_label = $Panel/PercentageEnemiesLabel
@onready var enemies_title_label = $Panel/EnemiesEvolutionTitleLabel
@onready var enemies_damage_label = $Panel/EnnemiesPercentageWinDamage
@onready var enemies_life_label = $Panel/EnememiesPercentageWinLife
@onready var star_title_label = $Panel/StarTitleLabel
@onready var star_label = $Panel/StarLabel
@onready var medal_texture = $Panel2/MedalTexture

var bronze_medal = preload("res://Hud/ScoreScreen/Medals/medal_bronze.png")
var silver_medal = preload("res://Hud/ScoreScreen/Medals/medal_silver.png")
var gold_medal = preload("res://Hud/ScoreScreen/Medals/medal_gold.png")
var banana_medal = preload("res://Hud/ScoreScreen/Medals/medal_banana.png")


func _ready():
	layer = 150
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func show_score(level_name, killed, total, stars, medal, percent, _moko_bonus, enemy_bonus):
	get_tree().paused = true

	level_name_label.text = level_name

	title_label.text = "ENNEMIS TUÉS"
	kill_label.text = str(killed) + " / " + str(total)

	level_mastery_title_label.text = "MAÎTRISE DU NIVEAU"
	enemies_percentage_label.text = str(percent) + "%"

	enemies_title_label.text = "LES CRÉATURES ÉVOLUENT :"
	enemies_damage_label.text = "+" + str(enemy_bonus) + "% dégâts"
	enemies_life_label.text = "+" + str(enemy_bonus) + "% points de vie"

	star_title_label.text = "Succès :"

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
