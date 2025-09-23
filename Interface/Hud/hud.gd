extends CanvasLayer

@onready var ramp_button = $Gamepad/Ramp
@onready var coco_button = $Gamepad/Coco
@onready var lance_button = $Gamepad/Spear
@onready var health_button = $Gamepad/Health

@onready var life_sprites = $HBoxContainerLive.get_children()

func _ready():
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.hud = self
	
	$Gamepad/Hand.pressed.connect(_on_hand_pressed)
	
	update_lives_display(game_state.lives)
	
	set_button_enabled(ramp_button, false)
	set_button_enabled(coco_button, false)
	set_button_enabled(lance_button, false)
	set_button_enabled(health_button, false)

func update_lives_display(lives):
	if not life_sprites.is_empty():
		life_sprites = $HBoxContainerLive.get_children()
	for i in range(life_sprites.size()):
		life_sprites[i].visible = i < lives

func start_banane_cooldown(duration_sec):
	var cooldown = $HBoxContainerBanane/Texture/coolDownCircle
	cooldown.value = 100
	cooldown.show()

	var tween = create_tween()
	tween.tween_property(cooldown, "value", 0, duration_sec).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func(): cooldown.hide())

func set_button_enabled(button, enabled):
	if button is TouchScreenButton:
		var shape = button.get_node_or_null("CollisionShape2D")
		if shape:
			shape.disabled = not enabled
		if enabled:
			button.modulate = Color(1, 1, 1, 1)
		else:
			button.modulate = Color(1, 1, 1, 0.4)

func update_hud_buttons(can_fire_coco, can_fire_lance, can_heal, can_ramp):
	set_button_enabled(coco_button, can_fire_coco)
	set_button_enabled(lance_button, can_fire_lance)
	set_button_enabled(health_button, can_heal)
	set_button_enabled(ramp_button, can_ramp)

func set_coco_button_enabled(enabled):
	set_button_enabled(coco_button, enabled)

func set_heal_button_enabled(enabled):
	set_button_enabled(health_button, enabled)

func set_lance_button_enabled(enabled):
	set_button_enabled(lance_button, enabled)

func update_seed_display(collected, total):
	var label = $HBoxContainerSeed/SeedCountLabel
	if total > 0:
		var percent = int(round(float(collected) / float(total) * 100))
		label.text = "%d / %d (%d%%)" % [collected, total, percent]
	else:
		label.text = "0 / 0 (0%)"

func _on_hand_pressed():
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.player:
		var player = game_state.player
		if player.has_method("clac_attack"):
			player.clac_attack()
