extends CanvasLayer

@onready var rect = $ColorRect
var fade_duration := 1.0

func _ready():
	rect.modulate.a = 0.0
	hide()

func fade_out():
	show()
	var tween = create_tween()
	tween.tween_method(_set_alpha, 0.0, 1.0, fade_duration)
	await tween.finished

func fade_in():
	show()
	var tween = create_tween()
	tween.tween_method(_set_alpha, 1.0, 0.0, fade_duration)
	await tween.finished
	hide()

func _set_alpha(value: float) -> void:
	var c = rect.modulate
	c.a = value
	rect.modulate = c
