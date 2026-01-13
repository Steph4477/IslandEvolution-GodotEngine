extends Node2D

@export var speed = 120.0
@export var turn_speed = 0.6

# Ondulation
@export var wave_amplitude = 6.0
@export var wave_frequency = 0.6

# angle directionel
@export var angle_deg = 0.0

# Durées simples (secondes)
@export var swim_time = 4.0
@export var idle_time = 2.0

@onready var sprite = $Sprite
@onready var anim = $AnimationPlayer
@onready var timer = $Timer
@onready var bounds_col = $SwimBounds/CollisionShape2D

var dir = Vector2.ZERO
var time = 0.0
var last_sin = 0.0

var min_bound = Vector2.ZERO
var max_bound = Vector2.ZERO

var is_idle = false

func _ready():
	var a = deg_to_rad(angle_deg)
	dir = Vector2(cos(a), sin(a)).normalized()

	var rect = bounds_col.shape                 # RectangleShape2D
	var ext = rect.extents                     # Demi-taille du rectangle (largeur/2, hauteur/2)
	var center = bounds_col.global_position    # Centre du rectangle dans la scène
	min_bound = center - ext                   # Coin haut-gauche du rectangle
	max_bound = center + ext                   # Coin bas-droit du rectangle


	_start_swim()

func _physics_process(delta):
	if is_idle:
		return

	time += delta

	# Changement de direction 
	dir = dir.rotated(turn_speed * delta).normalized()

	# avance
	global_position += dir * speed * delta

	# ondulation douce
	var s = sin(time * TAU * wave_frequency) * wave_amplitude
	global_position.y += s - last_sin
	last_sin = s
	
	
	# blocage + rebond
	if global_position.x < min_bound.x: # La tortue a traversé le mur gauche
		global_position.x = min_bound.x # Elle est replacée pile sur le mur
		dir.x = -dir.x # Elle repart dans l’autre sens
	if global_position.x > max_bound.x:
		global_position.x = max_bound.x
		dir.x = -dir.x

	if global_position.y < min_bound.y:
		global_position.y = min_bound.y
		dir.y = -dir.y
	if global_position.y > max_bound.y:
		global_position.y = max_bound.y
		dir.y = -dir.y

	# flip sprite
	if dir.x < 0:
		sprite.scale.x = -abs(sprite.scale.x)
	else:
		sprite.scale.x = abs(sprite.scale.x)

func _on_timer_timeout():
	if is_idle:
		_start_swim()
	else:
		_start_idle()

func _start_idle():
	is_idle = true
	timer.wait_time = idle_time
	timer.start()

	anim.play("idle")

func _start_swim():
	is_idle = false
	timer.wait_time = swim_time
	timer.start()
	
	anim.play("swim")
