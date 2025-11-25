extends RigidBody2D

@export var speed = 1000
@export var max_distance = 800
@export var damage = 100

var direction = Vector2.RIGHT
var start_position = Vector2.ZERO
var has_initialized_trajectory = false
var did_hit = false

@onready var shape = $Area2D/CollisionShape2D
@onready var spr = $SpearSprite 

func _ready():
	# On remet de la gravité et on laisse tourner librement
	gravity_scale = 1.0          
	linear_damp = 0
	angular_damp = 0             
	freeze = false
	
	if shape:
		shape.disabled = false
	
	set_physics_process(true)

func _physics_process(_delta):
	if did_hit:
		return
	
	# On initialise la trajectoire pour le moteur
	if has_initialized_trajectory == false:
		start_position = global_position
		has_initialized_trajectory = true
		
		if direction.length() == 0:
			direction = Vector2.RIGHT
		
		# Vitesse de départ, la gravité modifie la trajectoire
		linear_velocity = direction.normalized() * speed
		
		# Rotation continue sur lui-même pendant tout le vol
		if direction.x < 0:
			angular_velocity = -10.0   # tourne dans un sens
		else:
			angular_velocity = 10.0    # tourne dans l'autre
		
	# Flip visuel selon la direction actuelle du mouvement
	var vx = linear_velocity.x
	if spr:
		if vx < 0:
			spr.flip_h = false
		else:
			spr.flip_h = true
	else:
		if vx < 0:
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
