extends Node2D

@export var dialogue_scene = preload("res://Interface/Dialogue/toucan_dialogue.tscn")
@export var dialogue_lines = [
	"Hé Moko !",
	"Balance-toi vite entre les lianes...",
	"Ramène-moi une fleur de nénuphar",
	"Si tu veux réussir mon défi, reviens ici, à cet endroit !",
	"Le chrono démarre dès que j'ai fini de parler !"
]

@export var reset_on_start = true
@export var stop_on_exit = false
@export var hide_on_exit = false
@export var can_repeat_challenge = false
@export var replay_dialogue_on_retry = false

var challenge_started = false
var challenge_completed = false
var dialogue_played = false

var gs
var chrono        # Hud/TimerChrono
var timer         # Timer local (assigné dans l’inspecteur)

func _ready():
	gs = get_node("/root/GameState")
	timer = $Timer
	call_deferred("_bind_hud_and_timer")

func _bind_hud_and_timer():
	# Attendre que le HUD soit créé par le GameState
	while gs and gs.hud == null:
		await get_tree().process_frame

	if not gs or not gs.hud:
		return

	chrono = gs.hud.get_node_or_null("TimerChrono")

# ================== ZONE ==================
func _on_zone_body_entered(body):
	var is_player = body.name == "Player" or body.is_in_group("Player")
	if not is_player:
		return

	if challenge_completed and not can_repeat_challenge:
		return

	if not challenge_started:
		if gs.toucan_dialogue_seen:
			_start_chrono()
		else:
			_start_dialogue_then_chrono()
			gs.toucan_dialogue_seen = true
		return

	if gs.has_flower and not challenge_completed:
		var time_left_ok = false
		if timer:
			time_left_ok = timer.time_left > 0
		elif chrono:
			time_left_ok = chrono.time_left > 0

		if time_left_ok:
			_validate_success()
		else:
			_fail_challenge()

func _on_zone_body_exited(body):
	var is_player = body.name == "Player" or body.is_in_group("Player")
	if not is_player:
		return

	if stop_on_exit:
		if timer:
			timer.stop()
		if chrono:
			chrono.stop_chrono()
	if hide_on_exit:
		if chrono:
			chrono.visible = false

# ================ DÉPART ================
func _start_dialogue_then_chrono():
	if gs.player:
		gs.player.can_move = false

	await get_tree().process_frame

	var dlg = dialogue_scene.instantiate()
	add_child(dlg)
	dlg.start(dialogue_lines)
	await dlg.finished

	if gs.player:
		gs.player.can_move = true

	dialogue_played = true
	_start_chrono()

func _start_chrono():
	gs.has_flower = false

	if chrono == null:
		return

	if reset_on_start:
		chrono.reset_chrono()

	chrono.visible = true
	chrono.start_chrono()

	if timer:
		timer.stop()
		timer.start()

	challenge_started = true
	challenge_completed = false

# ================ FIN : SUCCÈS / ÉCHEC ================
func _validate_success():
	challenge_completed = true
	challenge_started = false

	if timer:
		timer.stop()
	if chrono:
		chrono.stop_chrono()
		chrono.visible = false

	if gs.player:
		gs.player.show_info_popup("✅ Défi réussi !")

func _fail_challenge():
	challenge_completed = true
	challenge_started = false

	if timer:
		timer.stop()
	if chrono:
		chrono.stop_chrono()
		chrono.visible = false

	if gs.player:
		gs.player.show_info_popup("⏳ Temps écoulé... Défi raté.")

	gs.has_flower = false
	dialogue_played = true

# ================ CALLBACKS ================
func _on_timer_timeout():
	if not gs:
		return
	if not challenge_started or challenge_completed:
		return
	if not gs.has_flower:
		_fail_challenge()
