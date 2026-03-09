extends Node2D

signal challenge_win

@export var dialogue_scene = preload("res://Interface/Dialogue/toucan_dialogue.tscn")
@export var counter_time = preload("res://Levels/Lvl3/Environement/Counter_time/counter_time.tscn")
@export var dialogue_lines = [
	"Hé Moko !",
	"Balance-toi vite entre les lianes...",
	"Ramène-moi une fleur de nénuphar",
	"Reviens ici pour valider !",
	"Le chrono démarre maintenant !"
]

@export var dialogue_win = [
	"Oui Moko tu as réussi !",
	"Merci j'ai enfin ma fleur,",
	"depuis le temps que j'en rêvais !",
	"Maintenant, attention aux secousses !😊"
]

@export var reset_on_start = true
@export var stop_on_exit = false
@export var hide_on_exit = false

var gs
var chrono
var timer
var started = false

func _ready():
	gs = get_node("/root/GameState")
	timer = $Timer
	
	# Récup chrono HUD (attend que le HUD existe)
	while gs.hud == null:
		await get_tree().process_frame
	chrono = gs.hud.get_node("TimerChrono")

func _physics_process(_delta):
	# Si Moko meurt pendant le défi → stop + retry
	if started and gs.player.is_dead:
		started = false
		timer.stop()
		chrono.stop_chrono()
		chrono.visible = false
		gs.toucan_challenge_retry = true

# ================== ZONE ==================
func _on_zone_body_entered(_body):
	# Si la scène a été supprimée → rien ne se relance
	if not is_instance_valid(self):
		return
		
	# Relance 3,2,1 si un retry est prévu
	if gs.toucan_challenge_retry:
		gs.toucan_challenge_retry = false
		await retry_then_start()
		return
		
	# Démarrage si pas lancé
	if not started:
		if gs.toucan_dialogue_seen:
			start()
		else:
			await intro_then_start()
			gs.toucan_dialogue_seen = true
		return
		
	# Défi en cours : valider si fleur + temps restant
	if gs.has_flower:
		if timer.time_left > 0 or chrono.time_left > 0:
			win()
		else:
			lose()

func _on_zone_body_exited(_body):
	if stop_on_exit:
		timer.stop()
		chrono.stop_chrono()
	if hide_on_exit:
		chrono.visible = false

# ================== FLUX ==================
func intro_then_start():
	gs.player.can_move = false
	await get_tree().process_frame
	var dlg = dialogue_scene.instantiate()
	add_child(dlg)
	dlg.start(dialogue_lines)
	await dlg.finished
	gs.player.can_move = true
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
	gs.player.show_info("✅ Défi réussi !")
	
	# 1) Dialogue 
	await dialogue_win_toucan()
	
	# 2) On demande le focus grenouille (via gs) et on prévient lvl3
	gs.focus_cam_frog = true
	emit_signal("challenge_win")
	
	# 3) On supprime la scène
	if is_instance_valid(self):
		queue_free()

func lose():
	started = false
	timer.stop()
	chrono.stop_chrono()
	chrono.visible = false
	gs.player.show_info_popup("⏳ Temps écoulé, tu vas y arriver Moko !")
	gs.has_flower = false
	gs.toucan_challenge_retry = true
	gs.player.damage_mod.die()

# ================ DIALOGUE RETENTE ================
func retry_then_start():
	gs.player.can_move = false
	await get_tree().process_frame
	var dlg = dialogue_scene.instantiate()
	add_child(dlg)
	dlg.start(["Retente !"])
	await dlg.finished
	gs.player.can_move = true
	counter_time_start()

# ======== COMPTE A REBOURD RETENTE =============
func counter_time_start():
	gs.player.can_move = false
	await get_tree().process_frame
	var cptanim = counter_time.instantiate()
	add_child(cptanim)
	await get_tree().create_timer(1.6).timeout
	gs.player.can_move = true
	start()

# =============== DIALOGUE WIN =====================
func dialogue_win_toucan():
	gs.player.can_move = false
	await get_tree().process_frame
	var dlg = dialogue_scene.instantiate()
	dlg.challenge_win = true # informe le dialogue qu’on est dans un win pour afficher la fleur
	add_child(dlg)
	dlg.start(dialogue_win)
	await dlg.finished
	gs.player.can_move = true

# ================ TIMER ==================
func _on_timer_timeout():
	if not started:
		return
	if not gs.has_flower:
		lose()
