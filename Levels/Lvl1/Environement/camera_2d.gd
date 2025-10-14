extends Camera2D

@export var player_path: NodePath
var player: Node2D
var shake_timer := 0.0
var shake_intensity := 0.0

func _ready():
	make_current()
	if player_path != null and has_node(player_path):
		player = get_node(player_path)
	else:
		player = get_parent().get_node("Player") # fallback
		print("Player automatiquement assigné :", player)

func _process(delta):
	if not is_instance_valid(player):
		return

	var target_pos = player.global_position

	if shake_timer > 0.0:
		shake_timer -= delta
		target_pos += Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		shake_intensity = 0.0

	global_position = global_position.lerp(target_pos, 0.1)

func shake_camera(intensity := 6.0, duration := 0.2):
	shake_intensity = intensity
	shake_timer = duration
