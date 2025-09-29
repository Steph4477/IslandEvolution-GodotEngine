extends Node2D

@export var dialogue_scene = preload("res://Interface/dialogue_ui.tscn")

func _ready():
	# Musique de fond
	$Node2D/Sound/lvl2.play()
	# On attend pour tout charger
	await get_tree().process_frame

	# Récupérer la caméra du Player et augmenter sa limite top
	var gs = get_node("/root/GameState")
	if gs.player:
		var cam = gs.player.get_node("Camera2D")
		cam.limit_top = -250000
		cam.limit_right = 12000   
