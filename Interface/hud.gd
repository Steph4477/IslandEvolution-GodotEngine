extends CanvasLayer

func _ready():
	var game_state = get_node_or_null("/root/GameManagement/SceneContainer/GameState")
	game_state.health_bar = $HealthBar

func start_banane_cooldown(duration: float) -> void:
	var cooldown = $HBoxContainerBanane/Texture/coolDownCircle
	cooldown.value = 100
	cooldown.show()

	var tween := create_tween()
	tween.tween_property(cooldown, "value", 0, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func():
		cooldown.hide()
	)
