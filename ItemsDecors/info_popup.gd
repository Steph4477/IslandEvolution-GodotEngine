extends CanvasLayer

@onready var info_label = $InfoLabel

@export var float_distance := 40
@export var info_duration := 1.5

func show_info(txt: String) -> void:
	info_label.visible = true
	info_label.modulate = Color.WHITE
	info_label.text = txt

	if not info_label.label_settings:
		info_label.label_settings = LabelSettings.new()
	info_label.label_settings.font_size = 32
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD

	var viewport_size = get_viewport().get_visible_rect().size
	info_label.size = viewport_size * Vector2(0.8, 0.3)
	info_label.position = (viewport_size - info_label.size) / 2

	var tween = create_tween()
	tween.tween_property(info_label, "modulate:a", 1.0, 0.2)
	tween.tween_interval(info_duration - 0.4)
	tween.tween_property(info_label, "modulate:a", 0.0, 0.2)
	await tween.finished

	queue_free()
