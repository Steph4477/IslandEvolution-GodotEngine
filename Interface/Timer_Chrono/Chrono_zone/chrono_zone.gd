extends Node2D

@export var dialogue_scene = preload("res://Interface/Dialogue/toucan_dialogue.tscn")
@export var dialogue_lines = [
	"Hé Moko !",
	"Balance-toi vite entre les lianes...",
	"Ramène-moi une fleur de nénuphar",
	"Si tu veux réussir mon défi, reviens ici, à cet endroit !",
	"Le chrono démarre dès que j'ai fini de parler !"
]

@export var reset_on_start = true              # remet le chrono à start_time au départ
@export var stop_on_exit = false               # stop chrono quand on sort de la zone
@export var hide_on_exit = false               # cache chrono quand on sort de la zone
@export var trigger_once = false               # FALSE pour autoriser le retour dans la zone
@export var replay_dialogue_on_retry = false   # TRUE = rejoue le dialogue à chaque tentative
@export var chrono_node_path: NodePath         # optionnel : pointer directement TimerChrono dans HUD

var challenge_started = false
var challenge_resolved = false
var dialogue_played = false

func _ready():
	# connexion au signal finished du chrono
	call_deferred("_connect_chrono_signal")
	
	# connexion au signal player_updated du GameState
	var gs = get_node_or_null("/root/GameState")
	if gs:
		var p_d = Callable(self, "player_die")
		if not gs.is_connected("player_updated", p_d):
			gs.connect("player_updated", p_d)


func _physics_process(_delta):
	# Watchdog : si le signal 'finished' n'arrive pas, on vérifie quand même la fin
	if not challenge_started or challenge_resolved:
		return
	var gs = get_node_or_null("/root/GameState")
	if not gs:
		return
	var chrono = _get_chrono()
	if not chrono:
		return
	# Si le chrono est arrivé à 0 et que la fleur n'est PAS ramassée -> échec
	if not chrono.is_running and chrono.time_left == 0 and not gs.has_flower:
		_fail_challenge()

# ================== Signaux de la Zone (enfant Area2D nommé "Zone") ==================
func _on_zone_body_entered(body):
	if not body:
		return
	if not body.is_in_group("Player") and body.name != "Player":
		return

	# 1) Première entrée : dialogue + chrono (ou chrono seul si on ne veut plus rejouer)
	if not challenge_started:
		if replay_dialogue_on_retry or not dialogue_played:
			_start_toucan_then_chrono()
		else:
			_start_chrono_only()
		return

	# 2) Retour dans la zone : si fleur prise, on valide (si temps restant)
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_flower and not challenge_resolved:
		var chrono = _get_chrono()
		if chrono and chrono.time_left > 0:
			_validate_success()
		else:
			_fail_challenge()

func _on_zone_body_exited(body):
	if not body:
		return
	if not body.is_in_group("Player") and body.name != "Player":
		return
	if not stop_on_exit and not hide_on_exit:
		return

	var chrono = _get_chrono()
	if chrono:
		if stop_on_exit:
			chrono.stop_chrono()
		if hide_on_exit:
			chrono.visible = false

# ====================== DÉPART : Dialogue Toucan puis chrono ======================
func _start_toucan_then_chrono():
	var gs = get_node_or_null("/root/GameState")
	if not gs:
		return

	if gs.player:
		gs.player.can_move = false

	await get_tree().process_frame
	var dlg = dialogue_scene.instantiate()
	dlg.name = "DialogueUI"
	add_child(dlg)
	dlg.start(dialogue_lines)

	await dlg.finished

	if gs.player:
		gs.player.can_move = true

	_start_chrono_only()
	dialogue_played = true

func _start_chrono_only():
	# S’assure que le signal 'finished' est connecté avant de démarrer
	_connect_chrono_signal()

	# Reset l’état de la fleur à chaque (re)démarrage de défi
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.has_flower = false

	var chrono = _get_chrono()
	if chrono:
		if reset_on_start:
			chrono.reset_chrono()
		chrono.start_chrono()

	challenge_started = true
	challenge_resolved = false

# ============================ VALIDATION ============================
func _validate_success():
	if challenge_resolved:
		return
	challenge_resolved = true

	_disconnect_chrono_signal()

	var chrono = _get_chrono()
	if chrono:
		chrono.stop_chrono()
		chrono.visible = false

	_show_message("✅ Défi réussi !")
	# Exemple récompense :
	# var gs = get_node_or_null("/root/GameState")
	# if gs:
	#     gs.has_key = true
	#     gs.signal_key_collected()
# --- Echèc ---
func player_die(new_player):
	# Si le joueur n'existe plus (mort ou respawn)
	if new_player == null:
		var chrono = _get_chrono()
		if chrono:
			chrono.stop_chrono()
			chrono.visible = false
		_disconnect_chrono_signal()
		_reset_flags()

func _on_timer_chrono_finished():
	# Appelé via signal "finished" de TimerChrono (connecté dynamiquement)
	if challenge_resolved:
		return
	var gs = get_node_or_null("/root/GameState")
	if gs and not gs.has_flower:
		_fail_challenge()

func _fail_challenge():
	if challenge_resolved:
		return
	challenge_resolved = true

	_disconnect_chrono_signal()

	var chrono = _get_chrono()
	if chrono:
		chrono.stop_chrono()
		chrono.visible = false  # UX : on cache le chrono à l’échec

	_show_message("⏳ Temps écoulé... Défi raté.")

	# Reset complet pour permettre une nouvelle tentative
	_reset_flags()

func _reset_flags():
	challenge_started = false
	challenge_resolved = false

	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.has_flower = false  # le joueur devra ramasser la fleur à nouveau

# ================================ Utilitaires ================================
func _get_chrono():
	# 1) Chemin exporté prioritaire (si fourni)
	if chrono_node_path != NodePath():
		var node = get_node_or_null(chrono_node_path)
		if node:
			return node

	# 2) Cherche via GameState -> HUD
	var gs = get_node_or_null("/root/GameState")
	if not gs or not gs.hud:
		return null

	# Nom direct
	var chrono = gs.hud.get_node_or_null("TimerChrono")
	if chrono:
		return chrono

	# Recherche récursive tolérante
	return gs.hud.find_child("TimerChrono", true, false)

func _show_message(txt):
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.player and gs.player.has_method("show_info_popup"):
		gs.player.show_info_popup(txt)

# ============================ Connexions dynamiques ============================
func _connect_chrono_signal():
	var chrono = _get_chrono()
	if not chrono:
		return
	var cb = Callable(self, "_on_timer_chrono_finished")
	if not chrono.is_connected("finished", cb):
		chrono.connect("finished", cb)

func _disconnect_chrono_signal():
	var chrono = _get_chrono()
	if not chrono:
		return
	var cb = Callable(self, "_on_timer_chrono_finished")
	if chrono.is_connected("finished", cb):
		chrono.disconnect("finished", cb)
