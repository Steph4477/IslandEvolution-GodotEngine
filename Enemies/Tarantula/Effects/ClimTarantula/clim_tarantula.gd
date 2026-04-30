extends Node2D

signal finished_clim_down
signal finished_clim_up

@onready var anim = $AnimationPlayer
@onready var cam = $Tarantula/Camera2D

func start_clim_down():
	cam.make_current()
	anim.play("clim_down_local")

func start_clim_up():
	cam.make_current()
	anim.play("clim_up_local")

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "clim_down_local":
		finished_clim_down.emit()
		queue_free()

	if anim_name == "clim_up_local":
		finished_clim_up.emit()
		queue_free()
