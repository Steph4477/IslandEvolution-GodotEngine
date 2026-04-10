extends Control

@onready var icon = $TextureRect
@onready var bar = $TextureProgressBar

var gs

func _ready():
	gs = get_node("/root/GameState")
	gs.fire_buff_bar = self

	hide_buff()

	bar.max_value = 100
	bar.value = 100

func show_buff(duration):
	visible = true
	bar.max_value = 100
	bar.value = 100
	_refresh_layout()

func hide_buff():
	visible = false
	_refresh_layout()

func _refresh_layout():
	if get_parent() and get_parent().get_parent() and get_parent().get_parent().has_method("refresh_layout"):
		get_parent().get_parent().refresh_layout()

func update_timer(time_left, duration):
	if duration <= 0:
		bar.value = 0
		return

	var ratio = clamp(time_left / duration, 0.0, 1.0)
	bar.value = ratio * 100.0
