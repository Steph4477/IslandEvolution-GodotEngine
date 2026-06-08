extends Node2D

@export var banane_value = 5 
@export var heal_amount = GameBalance.PLAYER_HEAL["banana"]

var game_state
var collected = false

func _ready():
	game_state = get_node_or_null("/root/GameState")
	game_state.heal_amount = heal_amount # Initialise me montant de pv par potion


func _on_area_2d_body_entered(body: Node2D) -> void:
	if collected:
		return
	if body.is_in_group("Player"):
		collected = true
		body.collect_items.collect_banane(banane_value)
		queue_free()
