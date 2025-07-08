extends Area2D

@export var next_scene_path: String

var is_unlocked = false
var already_faded = false

func _ready():
	$CloseSprite.visible = true
	$CloseSprite.modulate = Color(1, 1, 1, 1)  # totalement opaque
	$OpenSprite.visible = false

	await get_tree().process_frame  # Attend que GameState soit prêt

	var gs = get_node_or_null("/root/GameState")
	if gs:
		if not gs.is_connected("key_collected", Callable(self, "on_key_collected")):
			gs.key_collected.connect(on_key_collected)

		is_unlocked = gs.has_key
		if is_unlocked:
			update_visual(true)

func update_visual(unlocked: bool) -> void:
	if has_node("CloseSprite"):
		$CloseSprite.visible = not unlocked
	if has_node("OpenSprite"):
		$OpenSprite.visible = unlocked

	monitoring = unlocked

func on_key_collected():
	is_unlocked = true

	# 🟡 Focus caméra + fade
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.current_level and gs.current_level.has_method("focus_camera_on_exit_and_fade"):
		await gs.current_level.focus_camera_on_exit_and_fade()

	# ✅ Une fois que la caméra est revenue → affiche temple ouvert + active sortie
	update_visual(true)

func _on_body_entered(body):
	if not monitoring:
		return

	if body.name == "Player" and body.has_node("anim"):
		var anim_player = body.get_node("anim")
		if anim_player.has_animation("door"):
			body.animation_locked = true
			body.set_physics_process(false)

			anim_player.play("door")
			await anim_player.animation_finished
			change_scene()

func change_scene():
	await get_tree().create_timer(0.2).timeout
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.load_level(next_scene_path)

func play_fade():
	if already_faded:
		return
	already_faded = true

	# ⚙️ Préparation des sprites
	$OpenSprite.visible = true                # déjà visible derrière
	$OpenSprite.modulate.a = 1.0              # totalement opaque
	$CloseSprite.visible = true               # au premier plan
	$CloseSprite.modulate.a = 1.0             # commence opaque

	# 💥 D'abord le tremblement
	await shake_temple(0.4, 4.0)

	# 🎬 Puis le fondu du CloseSprite
	await fade_close_sprite()

	# ✅ Fin du fade : le temple ouvert est maintenant visible
	$CloseSprite.visible = false


func shake_temple(duration: float = 0.3, intensity: float = 3.0) -> void:
	var original_pos := position
	var time_elapsed := 0.0
	var step := 0.02

	while time_elapsed < duration:
		var offset := Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		position = original_pos + offset
		await get_tree().create_timer(step).timeout
		time_elapsed += step

	position = original_pos


func fade_close_sprite() -> void:
	var duration := 1.0
	var steps := 20
	var delay := duration / steps

	for i in range(steps + 1):
		var alpha := 1.0 - float(i) / steps
		$CloseSprite.modulate.a = alpha
		await get_tree().create_timer(delay).timeout
