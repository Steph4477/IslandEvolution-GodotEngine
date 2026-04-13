extends Node2D

var player_in_zone = false
var player = null
var game_state
var is_crafting = false
var missing_feedback_locked = false

@onready var anim_player = $AnimationPlayer

func _ready():
	game_state = get_node("/root/GameState")

func _process(_delta):
	if player_in_zone and Input.is_action_just_pressed("interact"):
		try_craft()

func can_craft_fire():
	if game_state.wood_collected and game_state.stone_collected and game_state.fire_recipe_unlocked:
		return true

	return false

func try_craft():
	if is_crafting:
		return

	if can_craft_fire():
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
	anim_player.play("craft_fire")

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		player_in_zone = true
		player = body
		body.popups_mod.show_info('Appuie sur "E" pour utiliser l’autel')

func _on_area_2d_body_exited(body):
	if body.is_in_group("Player"):
		player_in_zone = false
		player = null

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "craft_fire":
		is_crafting = false
		on_craft_animation_finished()

func on_craft_animation_finished():
	if player:
		player.fire_buff_mod.unlock_fire_skill()
