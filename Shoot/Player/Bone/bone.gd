extends RigidBody2D

@export var speed = 1000
@export var max_distance = 800
@export var lifetime = 3.0

var damage = 0

var direction = Vector2.RIGHT
var start_position = Vector2.ZERO
var has_initialized_trajectory = false
var did_hit = false

@onready var shape = $Area2D/CollisionShape2D
@onready var spr = $Sprite 

func _ready():
	# Remet de la gravité et on laisse tourner librement
	gravity_scale = 1.0          
	linear_damp = 0
	angular_damp = 0             
	freeze = false
	
	if shape:
		shape.disabled = false
	
	set_physics_process(true)
	
	# Durée de vie max même si rien n'est touché
	if lifetime > 0:
		var t = get_tree().create_timer(lifetime)
		await t.timeout
		if not did_hit:
			_finish()

# Appelé par le Player : spell.start(pos, dir)
func start(spawn_position, dir, projectile_damage):
	damage = projectile_damage

	global_position = spawn_position

	if typeof(dir) == TYPE_VECTOR2:
		direction = dir.normalized()
	else:
		if dir < 0:
			direction = Vector2.LEFT
		else:
			direction = Vector2.RIGHT

	start_position = global_position

func _physics_process(_delta):
	if did_hit:
		return
	
	# Initialise la trajectoire pour le moteur 
	if has_initialized_trajectory == false:
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
	
	# Vitesse horizontale
	var vx = linear_velocity.x
	
	# Flip que si la vitesse horizontale est suffisante
	if abs(vx) > 10:
		if spr:
			if vx < 0:
				spr.flip_h = false
			else:
				spr.flip_h = true
	else:
		# Vitesse très faible -> arrête la rotation 
		angular_velocity = 0
	
	# Destruction si dépasse la portée
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
	if body.is_in_group("Enemies"):
		if body.has_method("on_hit"):
			body.on_hit(damage)
		
	_impact()
