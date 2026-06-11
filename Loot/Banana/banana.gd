extends Node2D

@export var loot_id = ""
@export var banane_value = 5 
@export var heal_amount = GameBalance.PLAYER_HEAL["banana"]

var gs
var collected = false

func _ready():
	gs = get_node_or_null("/root/GameState")
	gs.heal_amount = heal_amount

	if loot_id == "":
		loot_id = name

	call_deferred("check_collected")


func check_collected():
	if gs.collected_loot_ids.has(loot_id):
		queue_free()


func _on_area_2d_body_entered(body):
	if collected:
		return

	if body.is_in_group("Player"):
		collected = true
		body.collect_items.collect_banane(banane_value)
		gs.add_loot_collected(loot_id)
		queue_free()
