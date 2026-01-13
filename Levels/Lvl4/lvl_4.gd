extends Node2D

var cam
var gs

# --- Réglages du tremblement caméra et dégâts ---
@export var intensity = 50.0   # Intensité du shake de caméra
@export var duration = 3.0     # Durée du tremblement

func _ready():
	# Musiques d’ambiance
	$Node2D/Sound/BirdsSound.play()
	$Node2D/Sound/WaterSound.play()
	# --- Limite caméra ---
	await get_tree().process_frame
	gs = get_node("/root/GameState")
	cam = gs.player.get_node("Camera2D")
	cam.limit_top = -250000
	cam.limit_right = 8500
	cam.limit_bottom = 1400
