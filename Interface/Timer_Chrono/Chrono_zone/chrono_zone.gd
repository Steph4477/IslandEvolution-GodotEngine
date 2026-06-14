extends Node2D

signal challenge_win

@export var dialogue_scene = preload("res://Interface/Dialogue/toucan_dialogue.tscn")
@export var counter_time = preload("res://Levels/Lvl3/Environement/Counter_time/counter_time.tscn")
@export var dialogue_lines = [
	"Hé Moko !",
	"Balance-toi vite entre les lianes...",
	"Ramène-moi une fleur de nénuphar.",
	"Reviens ici pour valider je te recompenserai !",
	"Le chrono démarre maintenant !"
]

@export var dialogue_win = [
	"Merci Moko, tu as réussi !",
	"Tiens, voici ta récompense."
]

@export var reset_on_start = true
@export var stop_on_exit = false
@export var hide_on_exit = false

var gs
var chrono
var timer
var started = false
var in_intro = false

func _ready():
	gs = get_node("/root/GameState")
	timer = $Timer

	if gs.air_recipe_unlocked or gs.toucan_challenge_done:
		queue_free()
		return

	while gs.hud == null:
		await get_tree().process_frame

	chrono = gs.hud.get_node("TimerChrono")

func _physics_process(_delta):
	if started and gs.player and gs.player.is_dead:
		started = false
		timer.stop()
		chrono.stop_chrono()
		chrono.visible = false
		gs.toucan_challenge_retry = true

func _on_zone_body_entered(body):
	if not body.is_in_group("Player"):
		return

	if not is_instance_valid(self):
		return

	if in_intro:
		return

	if gs.air_recipe_unlocked:
		return

	if gs.toucan_challenge_retry:
		gs.toucan_challenge_retry = false
		await retry_then_start()
		return

	if not started:
		if gs.toucan_dialogue_seen:
			start()
		else:
			in_intro = true
			await intro_then_start()
			gs.toucan_dialogue_seen = true
			in_intro = false
		return

	if gs.has_flower:
		if timer.time_left > 0 or chrono.time_left > 0:
			win()
		else:
			lose()

func _on_zone_body_exited(body):
	if not body.is_in_group("Player"):
		return

	if stop_on_exit:
		timer.stop()
		chrono.stop_chrono()

	if hide_on_exit:
		chrono.visible = false

func intro_then_start():
	gs.player.disable_controls()
	await get_tree().process_frame

	var dlg = dialogue_scene.instantiate()
	add_child(dlg)
	dlg.start(dialogue_lines)
	await dlg.finished

	gs.player.enable_controls()
	start()

func start():
	gs.has_flower = false

	if reset_on_start:
		chrono.reset_chrono()

	chrono.visible = true
	chrono.start_chrono()
	timer.stop()
	timer.start()
	started = true

func win():
	started = false
	timer.stop()
	chrono.stop_chrono()
	chrono.visible = false

	if not gs.air_recipe_unlocked:
		gs.air_recipe_unlocked = true
		gs.player.popups_mod.show_info("📜 Recette récupérée")
	else:
		gs.player.popups_mod.show_info("✅ Défi réussi !")

	if not gs.air_recipe_dialog_shown:
		gs.air_recipe_dialog_shown = true
		await dialogue_win_toucan()

	gs.air_craft_revealed = true

	if gs.hud:
		gs.hud.appear_air_craft_quest()
		gs.hud.update_air_craft_checklist()

	gs.focus_cam_frog = true
	emit_signal("challenge_win")

	if is_instance_valid(self):
		queue_free()

func lose():
	started = false
	timer.stop()
	chrono.stop_chrono()
	chrono.visible = false

	gs.has_flower = false
	gs.toucan_challenge_retry = false
	gs.toucan_challenge_done = true
	gs.respawn_point_name = "SpawnPoint2"

	gs.player.popups_mod.show_info("⏳ Défi raté, Moko continue plus loin !")
	gs.player.damage_mod.die()

func retry_then_start():
	gs.player.disable_controls()
	await get_tree().process_frame

	var dlg = dialogue_scene.instantiate()
	add_child(dlg)
	dlg.start(["Retente !"])
	await dlg.finished

	gs.player.enable_controls()
	counter_time_start()

func counter_time_start():
	gs.player.disable_controls()
	await get_tree().process_frame

	var cptanim = counter_time.instantiate()
	add_child(cptanim)

	await get_tree().create_timer(1.6).timeout
	gs.player.enable_controls()
	start()

func dialogue_win_toucan():
	gs.player.disable_controls()
	await get_tree().process_frame

	var dlg = dialogue_scene.instantiate()
	dlg.challenge_win = true
	add_child(dlg)
	dlg.start(dialogue_win)
	await dlg.finished

	gs.player.enable_controls()

func _on_timer_timeout():
	if not started:
		return

	if not gs.has_flower:
		lose()
