extends Node2D

@onready var anim = $Path2D/PathFollow2D/AnimationPlayer

func _ready():
	anim.play("air")
	await anim.animation_finished
	queue_free()
