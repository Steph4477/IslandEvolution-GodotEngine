extends CanvasLayer

func _ready():
	var game_state = get_node_or_null("/root/GameManagement/SceneContainer/GameState")
	game_state.health_bar = $HealthBar
