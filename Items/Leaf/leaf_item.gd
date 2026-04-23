extends Node2D

var collected = false
var player = null
var appear_played = false

@onready var anim = $AnimationPlayer

func _ready():
	var gs = get_node("/root/GameState")

	if gs.leaf_collected:
		queue_free()
		return

	player = get_tree().get_first_node_in_group("Player")

func _process(_delta):
	if collected:
		return

	if appear_played:
		return

	if player == null:
		player = get_tree().get_first_node_in_group("Player")
		return

	var distance = global_position.distance_to(player.global_position)

	if distance <= 800:
		appear_played = true
		anim.play("appear_leaf")

func _on_area_2d_body_entered(body):
	if collected:
		return

	if body.is_in_group("Player"):
		collected = true
		body.collect_items.collect_leaf()

		var gs = get_node("/root/GameState")
		if gs.hud:
			gs.hud.update_air_craft_checklist()

		queue_free()
