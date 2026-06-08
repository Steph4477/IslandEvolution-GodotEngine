extends CanvasLayer

@export var max_value = GameBalance.PLAYER_MAX_PV

@onready var bar = $TextureProgressBar
@onready var hp_label = $HpLabel


func _ready():
	bar.max_value = max_value
	bar.value = max_value
	update_label()

	var _game_state = get_node_or_null("/root/GameState")
	if _game_state:
		_game_state.health_bar = self


func set_max_value(v):
	max_value = v
	bar.max_value = max_value
	update_label()


func set_value(v):
	bar.value = clamp(v, 0, max_value)
	update_label()


func update_health_bar(current, new_max_value):
	set_max_value(new_max_value)
	set_value(current)


func update_health_bar_current(current):
	set_value(current)


func update_label():
	hp_label.text = str(int(bar.value)) + " / " + str(int(max_value))
