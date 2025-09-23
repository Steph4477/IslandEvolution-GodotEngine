extends CanvasLayer

@export var max_value := 2000
@onready var bar := $TextureProgressBar

func _ready():
	bar.max_value = max_value
	bar.value = max_value

	# 🔗 Référence globale dans le GameState
	var _game_state = get_node_or_null("/root/GameState")
	if _game_state:
		_game_state.health_bar = self

# 🔧 Setter public
func set_max_value(v):
	if bar:
		bar.max_value = v

func set_value(v):
	if bar:
		bar.value = clamp(v, 0, bar.max_value)

func update_health_bar(current, new_max_value):
	set_max_value(new_max_value)
	set_value(current)

	# Sécurité visuelle
	if bar:
		bar.max_value = new_max_value
		bar.value = clamp(current, 0, new_max_value)

# 💥 Appelée en temps réel lors des dégâts
func update_health_bar_current(current):
	set_value(current)
