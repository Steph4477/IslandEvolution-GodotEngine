extends Node2D

@export var coco_value: int = 1
@export var activate_shooting: bool = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and body.has_method("collect_coco"):
		body.collect_coco(3, true)  
		queue_free()
