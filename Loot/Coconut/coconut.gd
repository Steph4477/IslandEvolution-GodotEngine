extends Node2D

@export var coco_value = 1
@export var activate_shooting = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.collect_items.collect_coco(3, true)  
		queue_free()
