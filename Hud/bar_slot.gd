extends VBoxContainer

@onready var breath_bar = $BreathBar
@onready var buff_container = $BuffContainer
@onready var speed_bar = $SpeedBar

func _ready():
	alignment = BoxContainer.ALIGNMENT_BEGIN
	add_theme_constant_override("separation", 40)

	_config_bar_node(breath_bar)
	_config_bar_node(buff_container)
	_config_bar_node(speed_bar)
	
	refresh_layout()

func _config_bar_node(node):
	node.size_flags_horizontal = Control.SIZE_FILL
	node.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

func refresh_layout():
	queue_sort()

func show_breath():
	breath_bar.visible = true
	refresh_layout()

func hide_breath():
	breath_bar.visible = false
	refresh_layout()

func show_buffs():
	buff_container.visible = true
	refresh_layout()

func hide_buffs():
	buff_container.visible = false
	refresh_layout()

func show_speed():
	speed_bar.visible = true
	refresh_layout()

func hide_speed():
	speed_bar.visible = false
	refresh_layout()
