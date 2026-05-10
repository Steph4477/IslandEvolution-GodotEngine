extends Node2D

@onready var player_spawn = $SpawnPoint

var cam

func _ready():
	await get_tree().process_frame

	var gs = get_node("/root/GameState")

	if gs.player == null:
		var player = gs.player_scene.instantiate()
		add_child(player)
		player.global_position = player_spawn.global_position
		gs.player = player
		gs.emit_signal("player_updated", player)
	
	# --- Limite caméra & assombrissement ---
	cam = gs.player.get_node("Camera2D")
	cam.limit_right = 1900
	cam.limit_bottom = 1000
	
