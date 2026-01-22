extends Node2D

@export var coco_value = 1
@export var banane_value = 1
@export var heal_amount = 500
@export var activate_shooting = false

var game_state

func _ready():
	game_state = get_node_or_null("/root/GameState")
	game_state.heal_amount = heal_amount # Initialise le montant de pv par potion


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.collect_items.collect_coco(5, true)
		queue_free()
	if body.is_in_group("Player"):
		body.collect_items.collect_banane(1)
		queue_free()  
