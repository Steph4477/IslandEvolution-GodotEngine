extends Node2D

@onready var anim = $AnimationPlayer

func _ready():
	anim.play("appear") # Animation de sortie

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		var gs = get_node_or_null("/root/GameState")
		if gs:
			gs.has_key = true
			gs.lvl1_key_done = true
			gs.emit_signal("key_collected")

			if gs.hud:
				gs.hud.update_lvl1_checklist()

		queue_free()
