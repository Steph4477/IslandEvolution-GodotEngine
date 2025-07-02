extends Node2D

@export var max_value := 100
@onready var bar := $ProgressBar

func _ready() -> void:
	bar.max_value = max_value
	bar.value = max_value
	set_green_fill()

func set_value(v: int) -> void:
	bar.value = clamp(v, 0, max_value)

func set_green_fill() -> void:
	var green_fill := StyleBoxFlat.new()
	green_fill.bg_color = Color(0.0, 1.0, 0.0)  # Vert vif
	bar.add_theme_stylebox_override("fill", green_fill)
