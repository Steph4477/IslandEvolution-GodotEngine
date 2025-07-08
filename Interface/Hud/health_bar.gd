extends CanvasLayer

@export var max_value := 2000
@onready var bar := $TextureProgressBar

func _ready():
	bar.max_value = max_value
	bar.value = max_value
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.health_bar = self  # 🩸 Affecte la vraie HealthBar séparée

func set_max_value(v: int):
	if bar:
		bar.max_value = v

func set_value(v: int):
	if bar:
		bar.value = clamp(v, 0, bar.max_value)
