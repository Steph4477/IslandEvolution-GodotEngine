extends CanvasLayer

@export var max_value = 100
@onready var bar = $TextureProgressBar

var gs

func _ready():
	gs = get_node("/root/GameState")
	gs.speed_bar = self   # Référence globale dans le GameState

	bar.max_value = max_value
	bar.value = max_value

# --- Setters simples ---
func set_max_value(v):
	bar.max_value = v

func set_value(v):
	bar.value = clamp(v, 0, bar.max_value)

func update_speed_bar(current, new_max_value):
	set_max_value(new_max_value)
	set_value(current)

func update_speed_bar_current(current):
	set_value(current)
