extends Node2D

@onready var anim = $AnimationPlayer

func _ready():
	anim.play("appear") # Animation de sortie

func _on_area_2d_body_entered(body):
	if body and body.has_method("collect_lance"):
		# Moko ramasse 3 lances et débloque le tir de lance
		body.collect_lance(3, true)
		queue_free()
