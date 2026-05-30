extends Area2D

@export var next_scene_path = "res://Levels/Lvl2/Lvl_2b/lvl_2b.tscn"

var is_unlocked = false
var open_anim_played = false

@onready var door_anim = $AnimationPlayer
@onready var door_collision = $CollisionShape2D
@onready var door_control = $Control

# --- Utilitaire popup ---
func show_info_popup(txt):
	var popup_scene = preload("res://Interface/Popup/Info_popup/info_popup.tscn")
	var popup = popup_scene.instantiate()
	get_tree().root.add_child(popup)
	await get_tree().process_frame
	popup.show_info(txt)

func _ready():
	# 1) État initial : caché + collision off
	if door_control:
		door_control.visible = false
	if door_collision:
		door_collision.disabled = true

	await get_tree().process_frame

	# 2) Connexion au signal global du GameState 
	var gs = get_node_or_null("/root/GameState")
	if gs:
		if not gs.is_connected("digicode_ok", Callable(self, "on_digicode_ok")):
			gs.digicode_ok.connect(on_digicode_ok)

# --- Reçoit le signal du GS quand le code est OK ---
func on_digicode_ok():
	is_unlocked = true
	# Affiche le visuel (Control) et active la collision
	if door_control:
		door_control.visible = true
	if door_collision:
		door_collision.disabled = false
	# Lance l'animation "open"
	if door_anim and door_anim.has_animation("open") and not open_anim_played:
		door_anim.play("open")
		await door_anim.animation_finished
		open_anim_played = true

# --- Entrée dans l'Area2D ---
func _on_body_entered(body):
	if body.name != "Player":
		return

	# Jouer l'anim du joueur puis changer de scène
	var player_anim = body.get_node("Node2D/Anim")
	if player_anim and player_anim.has_animation("door_2"):
		body.animation_locked = true
		player_anim.play("door_2")
		await player_anim.animation_finished
		body.set_physics_process(false)
		change_scene()

func change_scene():
	var gs = get_node_or_null("/root/GameState")
	if not gs:
		return

	# --- Affichage des statistiques de fin de niveau ---
	gs.score_system.calculate_stars()
	gs.score_system.print_level_stats()
	gs.show_score_screen()

	gs.load_level(next_scene_path)
