extends CanvasLayer

@export var max_value := 2000
@onready var bar := $TextureProgressBar

func _ready():
	bar.max_value = max_value
	bar.value = max_value

func set_max_value(v: int):
	bar.max_value = v

func set_value(v: int):
	bar.value = clamp(v, 0, bar.max_value)
