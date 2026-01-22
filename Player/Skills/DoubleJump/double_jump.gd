extends Node2D

@onready var col = $Area2D/Col

func _ready():
	col.disabled = true
	await get_tree().create_timer(2.0).timeout
	col.disabled = false

func _on_area_2d_body_entered(body):
	if col.disabled:
		return
	if body.is_in_group("Player"):
		body.collect_skills.collect_double_jump()
	queue_free()
