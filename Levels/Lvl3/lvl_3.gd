extends Node2D

@export var chrono_zone_path = NodePath("Node2D/ChronoZone")

@onready var anim = $Node2D/World/lianas/AnimationPlayer

func _ready():
	## Musique de fond
	$Node2D/Sound/lvl2.play()
	
	# Position initiale => anim calée à 0.0s
	if anim.has_animation("fall"):
		anim.current_animation = "fall"
		anim.seek(0.0, true)
		anim.stop()
		
	## On attend pour tout charger
	await get_tree().process_frame
	
	## Récupéreration du game state
	var gs = get_node("/root/GameState")
	
	# Assombrissement de Moko
	if gs.player:
		var moko = gs.player
		moko.get_node("Node2D/Sprite").modulate = Color(0.4, 0.4, 0.4)

# --- Signals ---

func _on_chrono_zone_challenge_win():
	if anim.has_animation("fall"):
		anim.play("fall")
