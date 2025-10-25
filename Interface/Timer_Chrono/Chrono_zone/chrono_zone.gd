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
@export var replay_dialogue_on_retry = false   # ignoré une fois le dialogue montré

# --- états ---
var challenge_started = false
var challenge_completed = false
var dialogue_played = false

# --- refs ---
var gs
var chrono        # HUD/TimerChrono pour l’affichage uniquement
var timer         # Timer de la scène, réglé dans l’inspecteur (signal timeout -> _on_timer_timeout)

func _ready():
	gs = get_node("/root/GameState")
	chrono = gs.hud.get_node("TimerChrono")
	timer = $Timer

	# player_updated pour couper proprement si respawn
	var cb_player = Callable(self, "_on_player_updated")
	if not gs.is_connected("player_updated", cb_player):
		gs.connect("player_updated", cb_player)

# ================== ZONE ==================
func _on_zone_body_entered(body):
	var is_player = body.name == "Player" or body.is_in_group("Player")
	if not is_player:
		return

	# déjà réussi et répétition interdite -> on sort
	if challenge_completed and not can_repeat_challenge:
		return

	# première entrée -> lancement (avec/sans dialogue)
	if not challenge_started:
		if gs.toucan_dialogue_seen:
			_start_chrono()
		else:
			_start_dialogue_then_chrono()
			gs.toucan_dialogue_seen = true
		return

	# défi en cours -> si joueur a la fleur, on valide selon le temps restant
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
		chrono.stop_chrono()
	if hide_on_exit:
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

	if reset_on_start:
		chrono.reset_chrono()

	chrono.visible = true
	chrono.start_chrono()

	if timer:
		timer.stop()
		timer.start()   # durée fixée dans l’Inspector

	challenge_started = true
	challenge_completed = false

# ================ FIN : SUCCÈS / ÉCHEC ================
func _validate_success():
	challenge_completed = true
	challenge_started = false

	if timer:
		timer.stop()
	chrono.stop_chrono()
	chrono.visible = false

	if gs.player:
		gs.player.show_info_popup("✅ Défi réussi !")

func _fail_challenge():
	challenge_completed = true
	challenge_started = false

	if timer:
		timer.stop()
	chrono.stop_chrono()
	chrono.visible = false

	if gs.player:
		gs.player.show_info_popup("⏳ Temps écoulé... Défi raté.")

	gs.has_flower = false
	dialogue_played = true   # on garde “une fois par partie”

# ================ CALLBACKS ================
# Timer de la scène (assigné via Inspector) -> timeout
func _on_timer_timeout():
	# Si le temps est fini pendant le run :
	# - sans fleur -> échec immédiat
	# - avec fleur -> l’échec sera acté à la prochaine entrée de zone (temps écoulé)
	if not gs:
		return

	if not challenge_started or challenge_completed:
		return

	if not gs.has_flower:
		_fail_challenge()
		return
	# a la fleur mais pas revenu à temps : on ne fait rien ici.
	# en réentrant dans la zone, le test "time_left_ok" échouera => _fail_challenge().

# Couper net si le joueur change (mort/respawn)
func _on_player_updated(_new_player):
	if timer:
		timer.stop()
	chrono.stop_chrono()
	chrono.visible = false
	challenge_started = false
