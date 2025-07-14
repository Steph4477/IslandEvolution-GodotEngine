extends CanvasLayer

@export var max_value := 2000
@onready var bar := $TextureProgressBar

func _ready():
	bar.max_value = max_value
	bar.value = max_value

	# 🔗 Référence globale dans le GameState
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.health_bar = self

# 🔧 Setter public
func set_max_value(v: int) -> void:
	if bar:
		bar.max_value = v

func set_value(v: int) -> void:
	if bar:
		bar.value = clamp(v, 0, bar.max_value)

func update_health_bar(current: int, max: int) -> void:
	set_max_value(max)
	set_value(current)

	# Sécurité visuelle
	if bar:
		bar.max_value = max
		bar.value = clamp(current, 0, max)


# 💥 Appelée en temps réel lors des dégâts
func update_health_bar_current(current: int) -> void:
	set_value(current)
