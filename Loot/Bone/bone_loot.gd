extends Node2D

@export var bone_value = 1
@export var activate_shooting = false

@onready var anim = $AnimationPlayer
@onready var collision = $Path2D/PathFollow2D/Area2D/CollisionShape2D

func _ready():
	# Désactive la collision pendant l'animation d'apparition
	collision.disabled = true
	anim.play("appear")
	await anim.animation_finished
	
	# Anim terminée, on réactive la collision
	collision.disabled = false

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		body.collectItems.collect_bone(3, true)
		queue_free()
