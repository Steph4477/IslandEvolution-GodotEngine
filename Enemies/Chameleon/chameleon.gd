extends Node2D

@onready var anim = $AnimationPlayer
@onready var cycle_timer = $CycleTimer
@onready var window_timer = $WindowTimer

@onready var camo_collision = $Camouflage/CamouflageArea/CollisionShape2D
@onready var camo_node = $Camouflage

var gs = null

var camouflage_active = false
var player_in_zone = false
var looted = false
var player = null


func _ready():
	gs = get_node("/root/GameState")

	camo_collision.disabled = true
	camo_node.visible = false

	anim.play("idle")


func _process(_delta):
	if looted:
		return
	if not camouflage_active:
		return
	if not player_in_zone:
		return
	if Input.is_action_just_pressed("interact"):
		collect_camouflage()


# =================================================
#                     LOOT ZONE 
# =================================================

func _on_loot_zone_body_entered(body):
	if looted:
		return
	if not body.is_in_group("Player"):
		return

	player_in_zone = true
	player = body

	camo_node.visible = true
	anim.play("appear")

	if cycle_timer.is_stopped():
		cycle_timer.start()
		start_cycle()


func _on_loot_zone_body_exited(body):
	if not body.is_in_group("Player"):
		return

	player_in_zone = false
	player = null

	cycle_timer.stop()
	window_timer.stop()
	stop_camouflage_window()

	camo_node.visible = false
	anim.play("idle")


# =================================================
#             CYCLE / FENÊTRE D’INTERACTION
# =================================================

func start_cycle():
	if looted:
		return
	if not player_in_zone:
		return

	await get_tree().create_timer(0.5).timeout

	if looted:
		return
	if not player_in_zone:
		return

	start_camouflage_window()
	window_timer.start()


func _on_cycle_timer_timeout():
	start_cycle()


func _on_window_timer_timeout():
	stop_camouflage_window()


func start_camouflage_window():
	camouflage_active = true
	camo_collision.disabled = false

	if player_in_zone:
		show_info_popup("Moko appuie sur E pour attraper le camouflage !")


func stop_camouflage_window():
	camouflage_active = false
	camo_collision.disabled = true
	hide_info_popup()


# =================================================
#                          LOOT
# =================================================

func collect_camouflage():
	looted = true
	camouflage_active = false
	player_in_zone = false

	hide_info_popup()

	cycle_timer.stop()
	window_timer.stop()

	camo_collision.disabled = true
	camo_node.visible = false
	anim.play("idle")

	# Donne le skill à Moko
	if player and player.has_method("collect_camouflage"):
		player.collect_camouflage()

	# --- GameState : déblocage + HUD ---
		gs.camouflage_unlocked = true
		gs.camouflage_count += 1
		
		gs.hud.update_camouflage_display()
		gs.hud.refresh_hud_buttons()

	# Message de confirmation (2s)
	show_info_popup("C'est bien Moko :) Tu peux maintenant te camoufler !")
	get_tree().create_timer(2.0).timeout.connect(hide_info_popup)


# =================================================
# POPUP INFO
# =================================================

func show_info_popup(txt):
	var popup = get_tree().get_first_node_in_group("info_overlay_group")
	if popup == null:
		popup = preload("res://Interface/Popup/Info_popup/info_popup.tscn").instantiate()
		add_child(popup)
	popup.show_persistent(txt)


func hide_info_popup():
	var popup = get_tree().get_first_node_in_group("info_overlay_group")
	if popup == null:
		return
	popup.hide_persistent()
