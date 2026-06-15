extends Node2D

var gs
var collected = false
@onready var col = $Area2D/CollisionShape2D
@onready var anim = $AnimationPlayer

func _ready():
	anim.play("appear_skill_air")
	gs = get_node("/root/GameState")

	if gs.air_buff_unlocked:
		queue_free()
	
	col.disabled = true

	await get_tree().create_timer(0.8).timeout
	col.disabled = false
	anim.play("tornado_spin")

func _on_area_2d_body_entered(body):
	if collected:
		return

	if body.is_in_group("Player"):
		collected = true
		body.collect_skills.collect_air()
		queue_free()
