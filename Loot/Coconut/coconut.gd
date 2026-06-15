extends Node2D

@export var loot_id = ""
@export var coco_value = 3
@export var activate_shooting = true

var gs
var collected = false

func _ready():
	gs = get_node("/root/GameState")

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

		body.collect_items.collect_coco(coco_value, activate_shooting)

		gs.add_loot_collected(loot_id)

		queue_free()
