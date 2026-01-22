extends Node2D

@onready var anim = $Path2D/PathFollow2D/AnimationPlayer

@export var oxygen_value = 10
func _ready():
	anim.play("air")
	await anim.animation_finished
	queue_free()


func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		body.collect_skills.collect_oxygen(oxygen_value)
	queue_free()
