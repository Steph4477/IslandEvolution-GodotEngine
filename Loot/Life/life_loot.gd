extends Node2D
@onready var anim = $AnimationPlayer

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		var gained = get_node("/root/GameState").gain_life()
		if gained:
			anim.play("loot")
			await anim.animation_finished
			queue_free()
