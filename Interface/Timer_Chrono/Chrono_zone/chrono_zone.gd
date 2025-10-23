extends Node2D
@export var reset_on_enter = true   # remet à start_time en entrant
@export var stop_on_exit = true     # stop quand on sort de la zone
@export var hide_on_exit = true     # cache quand on sort de la zone
@export var trigger_once = false    # un seul déclenchement si true

var already_triggered = false

func _on_chrono_zone_body_entered(body):
	if trigger_once and already_triggered:
		return

	# cible Player
	if not body or (not body.is_in_group("Player") and body.name != "Player"):
		return

	var gs = get_node_or_null("/root/GameState")
	if not gs or not gs.hud:
		return
	var chrono = gs.hud.get_node_or_null("TimerChrono")
	if not chrono:
		return

	if reset_on_enter:
		chrono.reset_chrono()
	chrono.start_chrono()   # visible = true et is_running = true
	already_triggered = true

func _on_chrono_zone_body_exited(body):
	if not stop_on_exit and not hide_on_exit:
		return

	if not body or (not body.is_in_group("Player") and body.name != "Player"):
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
		chrono.hide_chrono()
