extends CanvasLayer

@onready var ramp_button = $Gamepad/Ramp
@onready var coco_button = $Gamepad/Coco
@onready var spear_button = $Gamepad/Spear
@onready var health_button = $Gamepad/Health

func _ready():
	var game_state = get_node_or_null("/root/GameManagement/SceneContainer/GameState")
	game_state.health_bar = $HealthBar

	# Tout griser au début
	set_button_enabled(ramp_button, false)
	set_button_enabled(coco_button, false)
	set_button_enabled(spear_button, false)
	set_button_enabled(health_button, false)

func start_banane_cooldown(duration: float) -> void:
	var cooldown = $HBoxContainerBanane/Texture/coolDownCircle
	cooldown.value = 100
	cooldown.show()

	var tween := create_tween()
	tween.tween_property(cooldown, "value", 0, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func():
		cooldown.hide()
	)

# 🔁 Fonction factorisée
func set_button_enabled(button: TouchScreenButton, enabled: bool) -> void:
	if button is TouchScreenButton:
		var shape := button.get_node_or_null("CollisionShape2D")
		if shape:
			shape.disabled = not enabled
		button.modulate = Color(1, 1, 1, 1) if enabled else Color(1, 1, 1, 0.4)

# 🔁 Met à jour l'état des boutons selon les flags du joueur
func update_hud_buttons(can_fire_coco: bool, can_heal: bool) -> void:
	set_button_enabled(coco_button, can_fire_coco)
	set_button_enabled(health_button, can_heal)
