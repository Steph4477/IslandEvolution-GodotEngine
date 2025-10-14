extends Node2D

@export var coco_value: int = 1
@export var banane_value: int = 1
@export var heal_amount = 500
@export var activate_shooting: bool = false

var game_state

func _ready() -> void:
	game_state = get_node_or_null("/root/GameState")
	game_state.heal_amount = heal_amount # Initialise me montant de pv par potion


func _on_area_2d_body_entered(body: Node2D) -> void:
	
	if body.is_in_group("Player") and body.has_method("collect_coco"):
		body.collect_coco(5, true)
		queue_free()
	if body.is_in_group("Player") and body.has_method("collect_banane"):
		body.collect_banane(1)
		queue_free()  
