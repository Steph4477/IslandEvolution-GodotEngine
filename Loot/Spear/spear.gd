extends Node2D

@export var loot_id = ""
@onready var anim = $AnimationPlayer

var gs
var collected = false

func _ready():
	gs = get_node_or_null("/root/GameState")

	if loot_id == "":
		loot_id = name

	if gs.collected_loot_ids.has(loot_id):
		queue_free()
		return

	anim.play("appear")

func _on_area_2d_body_entered(body):
	if collected:
		return

	if body.is_in_group("Player"):
		collected = true
		body.collect_items.collect_lance(3)
		gs.add_loot_collected(loot_id)
		queue_free()
