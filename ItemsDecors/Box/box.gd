extends RigidBody2D

@onready var area = $Area2D

var is_push_mode_enabled = false
var player_in_range = false

func _ready():
	freeze = true  # on bloque le corps au départ
	gravity_scale = 0.0  # empêche toute chute

	# Connexion des signaux de détection
	area.body_entered.connect(_on_area_2d_body_entered)
	area.body_exited.connect(_on_area_2d_body_exited)

func _process(delta):
	# Toggle push
	if player_in_range and Input.is_action_just_pressed("push"):
		is_push_mode_enabled = !is_push_mode_enabled

		if is_push_mode_enabled:
			freeze = false
			print("🟢 Moko commence à pousser (mode activé)")
		else:
			freeze = true
			print("🔴 Moko arrête de pousser (mode désactivé)")

	# Si Moko part, désactivation auto
	if not player_in_range and is_push_mode_enabled:
		is_push_mode_enabled = false
		freeze = true
		print("🚪 Moko s'est éloigné, mode push désactivé")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = true
		print("✅ Moko est à proximité de la caisse")

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = false
		print("🚶‍♂️ Moko quitte la zone")
