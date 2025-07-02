extends Label

@export var float_distance := 40
@export var duration := 0.5

func show_damage(amount) -> void:
	print("show_damage appelé avec :", amount)

	# Gère le cas d'un nombre
	if typeof(amount) == TYPE_INT or typeof(amount) == TYPE_FLOAT:
		text = "-" + str(amount)
		modulate = Color.YELLOW
	else:
		text = str(amount)
		modulate = Color.LIGHT_GREEN  # ou autre couleur pour message informatif

	position.y = 0

	var tween = create_tween()
	tween.tween_property(self, "position:y", -float_distance, duration)
	tween.tween_property(self, "modulate:a", 0.0, duration)
	await tween.finished
	queue_free()
