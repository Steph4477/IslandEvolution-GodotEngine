extends Node2D

@export var loot_id = ""
@export var bone_value = 1
@export var activate_shooting = false

@onready var anim = $AnimationPlayer
@onready var collision = $Path2D/PathFollow2D/Area2D/CollisionShape2D

var gs
var collected = false

func _ready():
	gs = get_node_or_null("/root/GameState")

	if loot_id == "":
		loot_id = name

	call_deferred("check_collected")


func check_collected():
	if gs.collected_loot_ids.has(loot_id):
		queue_free()
		return

	collision.disabled = true
	anim.play("appear")
	await anim.animation_finished
	collision.disabled = false


func _on_area_2d_body_entered(body):
	if collected:
		return

	if body.is_in_group("Player"):
		collected = true
		body.collect_items.collect_bone(3, true)
		gs.add_loot_collected(loot_id)
		queue_free()
