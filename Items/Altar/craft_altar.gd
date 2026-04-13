extends Node2D

var player_in_zone = false
var player = null
var game_state

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
	if can_craft_fire():
		print("craft autorisé")
	else:
		print("craft refusé")


func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		player_in_zone = true
		player = body
		body.popups_mod.show_info('Appuie sur "E" pour utiliser l’autel')


func _on_area_2d_body_exited(body):
	if body.is_in_group("Player"):
		player_in_zone = false
		player = null
