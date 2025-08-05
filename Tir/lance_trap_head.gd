extends CharacterBody2D

@export var speed := 800.0
@export var lifetime := 10.0
@export var damage := 1000
@export var detection_range := 2000.0
@export var delay_before_fire := 3.0

var direction: Vector2 = Vector2.ZERO
var has_collided := false
var player: Node2D
var has_launched := false

func _ready():
	find_and_bind_player()
	await get_tree().create_timer(lifetime).timeout
	if is_inside_tree():
		queue_free()

func _physics_process(delta):
	if not is_instance_valid(player):
		return

	var distance = global_position.distance_to(player.global_position)
	
	if not has_launched and distance <= detection_range:
		has_launched = true
		await launch_toward_player()

	if has_launched and not has_collided:
		velocity = direction * speed
		move_and_slide()

func launch_toward_player():
	await get_tree().create_timer(delay_before_fire).timeout

	if not is_instance_valid(player):
		return

	var target_pos: Vector2 = player.global_position

	# ✅ Vise le nœud TurnAxisHead s’il existe
	target_pos = player.get_node("TurnAxisHead").global_position

	direction = (target_pos - global_position).normalized()
	velocity = direction * speed  

func find_and_bind_player():
	var gs = get_node_or_null("/root/GameState")
	player = gs.player
	gs.connect("player_updated", Callable(self, "_on_player_changed"))

func _on_player_changed(new_player: Node):
	player = new_player

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("on_hit"):
		body.on_hit(damage)
		queue_free()
