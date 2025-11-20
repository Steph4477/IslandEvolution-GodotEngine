extends RigidBody2D

@export var speed = 1000
@export var max_distance = 800
@export var damage = 100

var direction = Vector2.RIGHT
var start_position = Vector2.ZERO
var has_start_position = false
var did_hit = false

@onready var hitbox = $Area2D
@onready var shape = $Area2D/CollisionPolygon2D
@onready var spr = $SpearSprite if has_node("SpearSprite") else null

func _ready():
	# Pas de gravité ni rotation parasite
	gravity_scale = 0
	linear_damp = 0
	angular_damp = 100000.0
	freeze = false

	if shape:
		shape.disabled = false

	set_physics_process(true)

func _physics_process(_delta):
	if did_hit:
		return

	# On fixe la position de départ **après** que le pygmée ait placé la lance
	if not has_start_position:
		start_position = global_position
		has_start_position = true

	# Mouvement droit, sans arc ni chute
	if direction.length() == 0:
		direction = Vector2.RIGHT

	linear_velocity = direction.normalized() * speed

	# Flip visuel selon la direction
	if spr:
		if direction.x < 0:
			spr.flip_h = false
		else:
			spr.flip_h = true
	else:
		if direction.x < 0:
			scale.x = abs(scale.x)
		else:
			scale.x = -abs(scale.x)

	# Destruction si on dépasse la portée
	var traveled = global_position.distance_to(start_position)
	if traveled >= max_distance:
		_finish()

func _impact():
	did_hit = true
	set_physics_process(false)
	_finish()

func _finish():
	queue_free()

func _on_area_2d_body_entered(body):
	if did_hit:
		return

	if is_instance_valid(body) and body.is_in_group("Player") and body.has_method("on_hit"):
		body.on_hit(damage)

	_impact()
