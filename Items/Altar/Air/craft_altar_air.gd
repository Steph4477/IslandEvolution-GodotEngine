extends Node2D

var player_in_zone = false
var player = null
var gs
var is_crafting = false
var missing_feedback_locked = false
var air_skill_scene = preload("res://Player/Skills/Air/air.tscn")
var air_skill_spawned = false
var air_spawn_position = Vector2.ZERO

@onready var anim_player = $AnimationPlayer
@onready var fire_left = $FireLeft
@onready var fire_right = $FireRight

func _ready():
	gs = get_node("/root/GameState")
	fire_left.visible = false
	fire_right.visible = false

func _process(_delta):
	if player_in_zone and Input.is_action_just_pressed("interact"):
		try_craft()

func can_craft_air():
	if gs.leaf_collected and gs.idole_collected and gs.air_recipe_unlocked:
		return true

	return false

func try_craft():
	if is_crafting:
		return

	if can_craft_air():
		start_craft_animation()
	else:
		show_missing_elements_feedback()

func show_missing_elements_feedback():
	if missing_feedback_locked:
		return

	missing_feedback_locked = true

	if player:
		player.popups_mod.show_info("Il manque des éléments...")

	await get_tree().create_timer(2.0).timeout
	missing_feedback_locked = false

func start_craft_animation():
	is_crafting = true
	air_spawn_position = global_position + Vector2(0, -40)

	if player:
		air_spawn_position = player.global_position + Vector2(0, -40)

	anim_player.play("craft_fire")

func spawn_air_skill():
	if air_skill_spawned:
		return

	air_skill_spawned = true

	var air_skill = air_skill_scene.instantiate()
	get_parent().add_child(air_skill)
	air_skill.global_position = air_spawn_position

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		player_in_zone = true
		player = body
		body.popups_mod.show_info('Appuie sur "E" pour utiliser l’autel')

		if not gs.air_altar_found:
			gs.air_altar_found = true
			if gs.hud:
				gs.hud.update_air_craft_checklist()

func _on_area_2d_body_exited(body):
	if body.is_in_group("Player"):
		player_in_zone = false
		player = null

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "craft_fire":
		is_crafting = false
		on_craft_animation_finished()

func on_craft_animation_finished():
	spawn_air_skill()
