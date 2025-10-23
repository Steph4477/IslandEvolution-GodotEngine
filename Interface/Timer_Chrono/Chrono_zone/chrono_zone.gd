extends Node2D

@export var dialogue_scene = preload("res://Interface/Dialogue/toucan_dialogue.tscn")
@export var dialogue_lines = [
	"Hé Moko !",
	"Balance-toi vite entre les lianes...",
	"Ramène-moi une fleur de nénuphar",
	"Si tu veux réussir mon défi",
	"Le chrono démarre dès que j'ai fini de parler !"
]

@export var reset_on_start = true     # remet le chrono à start_time avant départ
@export var stop_on_exit = false      # stop chrono quand on sort de la zone
@export var hide_on_exit = false      # cache chrono quand on sort de la zone
@export var trigger_once = true       # ne déclenche qu'une fois

var already_triggered = false
var running_dialog = false

func _on_chrono_zone_body_entered(body):
	if not body or (not body.is_in_group("Player") and body.name != "Player"):
		return
	if trigger_once and already_triggered:
		return
	if running_dialog:
		return

	running_dialog = true
	_start_toucan_then_chrono()

func _on_chrono_zone_body_exited(body):
	if not body or (not body.is_in_group("Player") and body.name != "Player"):
		return
	if not stop_on_exit and not hide_on_exit:
		return

	var gs = get_node_or_null("/root/GameState")
	if not gs or not gs.hud:
		return
	var chrono = gs.hud.get_node_or_null("TimerChrono")
	if not chrono:
		return

	if stop_on_exit:
		chrono.stop_chrono()
	if hide_on_exit:
		chrono.visible = false

func _start_toucan_then_chrono():
	var gs = get_node_or_null("/root/GameState")
	if not gs:
		running_dialog = false
		return

	# Bloque le mouvement de Moko 
	if gs.player:
		var moko = gs.player
		moko.can_move = false
		
	# Insertion du dialogue du Toucan 
	await get_tree().process_frame
	var dlg = dialogue_scene.instantiate()
	dlg.name = "DialogueUI"
	add_child(dlg)

	# Texte du dialogue 
	dlg.start(dialogue_lines)

	# Attendre la fin du dialogue 
	await dlg.finished

	# Réactiver le mouvement de Moko
	if gs.player:
		gs.player.can_move = true

	# Démarrer le chrono du HUD
	if gs.hud:
		var chrono = gs.hud.get_node_or_null("TimerChrono")
		if chrono:
			if reset_on_start:
				chrono.reset_chrono()
			chrono.start_chrono()  

	already_triggered = true
	running_dialog = false
