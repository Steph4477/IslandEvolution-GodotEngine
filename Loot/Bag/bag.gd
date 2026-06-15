extends Node2D

@export var loot_id = ""

var game_state
var collected = false

func _ready():
	game_state = get_node_or_null("/root/GameState")

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

		body.collect_items.collect_coco(5, true)
		body.collect_items.collect_banane(1)

		game_state.add_loot_collected(loot_id)

		queue_free()
