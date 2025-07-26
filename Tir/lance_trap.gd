extends CharacterBody2D

@export var speed := 800.0
@export var lifetime := 10.0
@export var damage := 100
@export var detection_range := 2000.0
@export var delay_before_fire := 0.5
@export var tracking_duration := 0.3  # Durée où la lance suit Moko
@export var tracking_strength := 0.1  # Vitesse d’ajustement de la direction (0 = lent)

var direction: Vector2 = Vector2.ZERO
var has_collided := false
var player: Node2D
var has_launched := false
var tracking_timer := 0.0


func _ready():
	find_and_bind_player()
	await get_tree().create_timer(lifetime).timeout
	if is_inside_tree():
		queue_free()


func _physics_process(delta):
	if not is_instance_valid(player):
		return

	if not has_launched:
		var distance = global_position.distance_to(player.global_position)
		if distance <= detection_range:
			has_launched = true
			await launch_toward_player()
	else:
		if tracking_timer < tracking_duration:
			tracking_timer += delta
			update_direction()

		set_velocity(direction * speed)
		move_and_slide()


func launch_toward_player():
	await get_tree().create_timer(delay_before_fire).timeout

	if not is_instance_valid(player):
		return

	update_direction()  # direction initiale

func update_direction():
	if not is_instance_valid(player):
		return

	var target_pos = player.global_position
	if player.has_node("TurnAxis"):
		target_pos = player.get_node("TurnAxis").global_position

	var desired_direction = (target_pos - global_position).normalized()
	direction = direction.lerp(desired_direction, tracking_strength).normalized()


func find_and_bind_player():
	var gs = get_node_or_null("/root/GameState")
	if gs:
		player = gs.player
		gs.connect("player_updated", Callable(self, "_on_player_changed"))


func _on_player_changed(new_player: Node):
	player = new_player
	print("🔄 [LanceTrap] Nouveau joueur affecté :", player)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if has_collided:
		return

	if body.is_in_group("Player"):
		has_collided = true
		body.on_hit(damage)
		queue_free()
