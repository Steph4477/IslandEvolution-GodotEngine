extends Node2D

@onready var anim = $AnimationPlayer
var is_lowered = false

func _ready():
	# Position initiale : pont en haut (anim calée à 0.0s)
	if anim.has_animation("lower"):
		anim.current_animation = "lower"
		anim.seek(0.0, true)
		anim.stop()

func _on_crank_activated():
	lower()

func lower():
	if is_lowered:
		return
	is_lowered = true
	if anim and anim.has_animation("lower"):
		anim.play("lower")
