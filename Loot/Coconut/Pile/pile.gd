extends Node2D

@export var loot_id = ""
@export var coco_value = 1
@export var banane_value = 1
@export var heal_amount = 500
@export var activate_shooting = false

var game_state
var collected = false

func _ready():
	game_state = get_node_or_null("/root/GameState")
	game_state.heal_amount = heal_amount

	if loot_id == "":
		loot_id = name

	call_deferred("check_collected")

func check_collected():
	if game_state.collected_loot_ids.has(loot_id):
		queue_free()

func _on_area_2d_body_entered(body):
	if collected:
		return

	if body.is_in_group("Player"):
		collected = true

		body.collect_items.collect_coco(20, true)
		body.collect_items.collect_banane(6)

		game_state.add_loot_collected(loot_id)

		queue_free()
