extends Node2D

signal key_collected

@onready var anim = $AnimationPlayer

func _ready():
	anim.play("appear") # Animation de sortie


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		emit_signal("key_collected")

		var gs = get_node_or_null("/root/GameState")
		if gs:
			gs.has_key = true
			gs.emit_signal("key_collected")  # ✅ GameState relaie l'info

			if gs.current_level and gs.current_level.has_method("focus_camera_on_exit_and_fade"):
				await gs.current_level.focus_camera_on_exit_and_fade()

		queue_free()
