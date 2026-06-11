extends Node2D

@export var seed_id = ""
@export var seed_value = 1

func _ready():
	if seed_id == "":
		seed_id = name

	call_deferred("check_collected")


func check_collected():
	var gs = get_node("/root/GameState")

	if gs.collected_seed_ids.has(seed_id):
		queue_free()


func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		body.collect_items.collect_seed(seed_id, seed_value)
		queue_free()
