extends Node2D

func _ready() -> void:
	$TurnOn.visible = false
	$TurnOff.visible = true
	
func _on_area_2d_body_entered(body) -> void:
	if body.is_in_group("Player"):
		$TurnOn.visible = true
		$TurnOff.visible = false
