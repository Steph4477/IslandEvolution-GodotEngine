extends Area2D

@export var next_scene_path = "res://Levels/Lvl2/lvl_2.tscn"

var is_unlocked = false
var already_faded = false

func show_info_popup(txt):
	var popup_scene = preload("res://Interface/Popup/Info_popup/info_popup.tscn")
	var popup = popup_scene.instantiate()
	get_tree().root.add_child(popup)
	await get_tree().process_frame
	popup.show_info(txt)

func _ready():
	$CloseSprite.visible = true
	$CloseSprite.modulate = Color(1, 1, 1, 1)
	$OpenSprite.visible = false

	await get_tree().process_frame

	var gs = get_node_or_null("/root/GameState")
	if gs:
		if not gs.is_connected("key_collected", Callable(self, "on_key_collected")):
			gs.connect("key_collected", Callable(self, "on_key_collected"))

		is_unlocked = gs.has_key
		if is_unlocked:
			update_visual(true)

func update_visual(unlocked):
	if has_node("CloseSprite"):
		$CloseSprite.visible = not unlocked
	if has_node("OpenSprite"):
		$OpenSprite.visible = unlocked

func on_key_collected():
	is_unlocked = true
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.current_level and gs.current_level.has_method("focus_camera_on_exit_and_fade"):
		await gs.current_level.focus_camera_on_exit_and_fade()
	update_visual(true)

func _on_body_entered(body):
	if body.name != "Player":
		return

	if not is_unlocked:
		show_info_popup("🔑 Il te faut la clé pour ouvrir la porte !")
		$LockedSound.play()
		return

	var anim_player = body.get_node("Node2D/Anim")
	if anim_player and anim_player.has_animation("door"):
		body.animation_locked = true
		anim_player.play("door")
		await anim_player.animation_finished
		body.set_physics_process(false)
		await _do_scene_change()
	else:
		await _do_scene_change()

func _do_scene_change():
	var gs = get_node_or_null("/root/GameState")
	if not gs:
		return
	await get_tree().create_timer(0.2).timeout
	gs.load_level(next_scene_path)

func play_fade():
	if already_faded:
		return
	already_faded = true

	$OpenSprite.visible = true
	$OpenSprite.modulate.a = 1.0
	$CloseSprite.visible = true
	$CloseSprite.modulate.a = 1.0

	await shake_temple(0.4, 4.0)
	await fade_close_sprite()
	$CloseSprite.visible = false

func shake_temple(duration = 0.3, intensity = 3.0):
	var original_pos = position
	var time_elapsed = 0.0
	var step = 0.02

	while time_elapsed < duration:
		var offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		position = original_pos + offset
		await get_tree().create_timer(step).timeout
		time_elapsed += step

	position = original_pos

func fade_close_sprite():
	var duration = 1.0
	var steps = 20
	var delay = duration / steps

	for i in range(steps + 1):
		var alpha = 1.0 - float(i) / steps
		$CloseSprite.modulate.a = alpha
		await get_tree().create_timer(delay).timeout
