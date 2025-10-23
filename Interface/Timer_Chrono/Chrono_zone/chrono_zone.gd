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
var chrono

func _ready():
	gs = get_node("/root/GameState")
	chrono = gs.hud.get_node("TimerChrono")

	var cb_chrono = Callable(self, "_on_timer_chrono_finished")
	if not chrono.is_connected("finished", cb_chrono):
		chrono.connect("finished", cb_chrono)

	var cb_player = Callable(self, "_on_player_updated")
	if not gs.is_connected("player_updated", cb_player):
		gs.connect("player_updated", cb_player)

# ================== ZONE ==================
func _on_zone_body_entered(body):
	if body.is_in_group("Player") == false and body.name != "Player":
		return

	if can_repeat_challenge and challenge_completed:
		return

	if challenge_started == false:
		if replay_dialogue_on_retry or dialogue_played == false:
			_start_dialogue_then_chrono()
		else:
			_start_chrono()
		return

	if gs.has_flower and challenge_completed == false:
		if chrono.time_left > 0:
			_validate_success()
		else:
			_fail_challenge()

func _on_zone_body_exited(body):
	if body.is_in_group("Player") == false and body.name != "Player":
		return

	if stop_on_exit:
		chrono.stop_chrono()
	if hide_on_exit:
		chrono.visible = false

# -- Départ ----
func _start_dialogue_then_chrono():
	gs.player.can_move = false

	await get_tree().process_frame

	var dlg = dialogue_scene.instantiate()
	add_child(dlg)
	dlg.start(dialogue_lines)
	await dlg.finished

	gs.player.can_move = true
	dialogue_played = true
	_start_chrono()

func _start_chrono():
	gs.has_flower = false
	if reset_on_start:
		chrono.reset_chrono()
	chrono.visible = true
	chrono.start_chrono()
	challenge_started = true
	challenge_completed = false

# --- Validation ---
func _validate_success():
	challenge_completed = true
	challenge_started = false
	chrono.stop_chrono()
	chrono.visible = false
	gs.player.show_info_popup("✅ Défi réussi !")

# --- echec ---
func _fail_challenge():
	challenge_completed = true
	challenge_started = false
	chrono.stop_chrono()
	chrono.visible = false
	gs.player.show_info_popup("⏳ Temps écoulé... Défi raté.")
	gs.has_flower = false
	if replay_dialogue_on_retry == false:
		dialogue_played = true

func _on_timer_chrono_finished():
	if challenge_completed:
		return
	if gs.has_flower == false:
		_fail_challenge()

func _on_player_updated(_new_player):
	chrono.stop_chrono()
	chrono.visible = false
	challenge_started = false
