extends Node2D

signal finished_clim_down
signal finished_clim_up

@onready var anim = $AnimationPlayer
@onready var cam = $Tarantula/Camera2D
@onready var cocoon = $Cocoon

func _ready():
	cocoon.visible = false

func start_clim_down():
	cam.make_current()
	anim.stop()
	cocoon.visible = false
	anim.play("clim_down_local")

func start_clim_up():
	anim.stop()
	cocoon.visible = false
	anim.play("clim_up_local")

func _on_animation_player_animation_finished(anim_name):

	if anim_name == "clim_down_local":
		cocoon.visible = false
		finished_clim_down.emit()
		queue_free()

	if anim_name == "clim_up_local":
		cocoon.visible = true
		finished_clim_up.emit()
		anim.play("heal")
