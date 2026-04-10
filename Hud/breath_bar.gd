extends Control

@export var max_value = 100
@onready var bar = $TextureProgressBar

var gs

func _ready():
	gs = get_node("/root/GameState")
	gs.breath_bar = self

	hide_bar()

	bar.max_value = max_value
	bar.value = max_value

func show_bar():
	visible = true
	_refresh_layout()

func hide_bar():
	visible = false
	_refresh_layout()

func _refresh_layout():
	if get_parent() and get_parent().has_method("refresh_layout"):
		get_parent().refresh_layout()

func set_max_value(v):
	bar.max_value = v

func set_value(v):
	bar.value = clamp(v, 0, bar.max_value)

func update_breath_bar(current, new_max_value):
	set_max_value(new_max_value)
	set_value(current)

func update_breath_bar_current(current):
	set_value(current)
