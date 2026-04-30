extends Node2D

signal finished_clim_down

@onready var anim = $AnimationPlayer

func start_clim_down():
	anim.play("clim_down")

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "clim_down":
		finished_clim_down.emit()
		queue_free()
