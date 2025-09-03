extends Node2D

signal lance_collected

@onready var anim = $AnimationPlayer

func _ready():
	anim.play("appear") # Animation de sortie


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		emit_signal("lance_collected")

		var gs = get_node_or_null("/root/GameState")
		if gs:
			gs.has_lance = true
			gs.emit_signal("lance_collected")  # ✅ GameState relaie l'info

		queue_free()
