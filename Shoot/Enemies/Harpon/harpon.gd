extends RigidBody2D

@export var speed = 1000
@export var damage = 500
@export var arc_force = -350
@export var gravity_force = 1.6

var direction = 1
var shooter_node = null
var has_hooked = false

@onready var sprite = $HarponSprite
@onready var hitbox = $Area2D/CollisionPolygon2D

func _ready():
	gravity_scale = gravity_force
	hitbox.disabled = true
	contact_monitor = true
	max_contacts_reported = 1

func setup_owner(shooter):
	shooter_node = shooter

func _physics_process(_delta):
	rotation = linear_velocity.angle()

func start(pos, target_pos):
	global_position = pos

	if target_pos.x < global_position.x:
		direction = -1
	else:
		direction = 1

	var dir = (target_pos - global_position).normalized()

	hitbox.disabled = false
	linear_velocity = Vector2(dir.x * speed, dir.y * speed + arc_force)

	if direction < 0:
		sprite.flip_v = true
	else:
		sprite.flip_v = false

func _on_area_2d_body_entered(body):
	if has_hooked:
		return

	if not body.is_in_group("Player"):
		return

	if body.is_harpooned:
		return

	has_hooked = true

	body.damage_mod.on_hit(damage)
	body.start_harpooned(shooter_node)

	shooter_node.harpoon_pull.create_rope(
	shooter_node.get_node("HarpoonShootPoint"),
	body.get_node("HarpoonAttachPoint")
)

	shooter_node.harpoon_pull.start_pull(body)

	queue_free()

func _on_body_entered(_body):
	if has_hooked:
		return

	queue_free()
