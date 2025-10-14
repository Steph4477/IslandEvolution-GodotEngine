extends Node2D

@onready var anim = $AnimationPlayer

func _ready():
	anim.play("appear") # Animation de sortie

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body and body.has_method("collect_lance"):
		body.collect_lance(true)  
	queue_free()
