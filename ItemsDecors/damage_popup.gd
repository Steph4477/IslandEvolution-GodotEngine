extends Label

@export var float_distance := 40
@export var duration := 0.5

func show_damage(amount) -> void:
	# Évite le spam de messages identiques
	if typeof(amount) == TYPE_STRING:
		for child in get_tree().get_nodes_in_group("popup_messages"):
			if child is Label and child.text == str(amount):
				queue_free()
				return

	# Gère le texte et la couleur
	if typeof(amount) == TYPE_INT or typeof(amount) == TYPE_FLOAT:
		text = "-" + str(amount)
		modulate = Color.YELLOW
	else:
		text = str(amount)
		modulate = Color.LIGHT_GREEN

	add_to_group("popup_messages")
	position.y = 0

	var tween = create_tween()
	tween.tween_property(self, "position:y", -float_distance, duration)
	tween.tween_property(self, "modulate:a", 0.0, duration)
	await tween.finished

	remove_from_group("popup_messages")
	queue_free()
