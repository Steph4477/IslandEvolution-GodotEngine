extends Node2D

@onready var anim = $AnimationPlayer

func _ready():
	anim.play("appear") # Animation de sortie

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		# Moko ramasse 3 lances et débloque le tir de lance
		body.collectItems.collect_lance(3, true)
		queue_free()
