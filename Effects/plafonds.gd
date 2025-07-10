extends Node2D
signal finished_descente

@onready var anim = $AnimationPlayer

func _ready():
	anim.play("descent")
	anim.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(name):
	if name == "descent":
		emit_signal("finished_descente")
		queue_free()
