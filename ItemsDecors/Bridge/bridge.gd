extends Node2D

@onready var anim = $AnimationPlayer
var is_lowered = false

func _ready():
	# Aligne le pont sur la 1ère frame de l’anim "lower" (position haute)
	if anim and anim.has_animation("lower"):
		anim.current_animation = "lower"
		anim.seek(0.0, true)  # applique immédiatement la pose du début
		anim.stop()

func lower():
	if is_lowered:
		return
	is_lowered = true
	if anim and anim.has_animation("lower"):
		anim.play("lower")

func _on_crank_activated():
	lower()
