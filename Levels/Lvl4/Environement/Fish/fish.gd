extends Node2D

@export var speed = 400.0
@export var wave_amplitude = 8.0
@export var wave_frequency = 1.2
@export var fish_color = Color(1, 1, 1, 1)

@export var dir_x = 1.0
@export var dir_y = 0.3

var air_bubble_scene = preload("res://Levels/Lvl4/Environement/Aquatic_breathing/Air_bubble/air_bubble.tscn")


@onready var visual = $Visual
@onready var sprite = $Visual/Sprite
@onready var anim = $AnimationPlayer
@onready var bounds_col = $SwimBounds/CollisionShape2D
@onready var air_spawn = $Visual/AirSpawn

var time = 0.0
var last_sin = 0.0
var dir = Vector2.ZERO
var min_bound = Vector2.ZERO
var max_bound = Vector2.ZERO

var duration_anim_swim = 0.8

func _ready():
	sprite.modulate = fish_color

	if anim.has_animation("Swim"):
		anim.play("Swim")

	dir = Vector2(dir_x, dir_y).normalized()

	var rect = bounds_col.shape
	var ext = rect.extents
	var center = bounds_col.global_position
	min_bound = center - ext
	max_bound = center + ext

func _physics_process(delta):
	time += delta

	# Déplacement
	global_position += dir * speed * delta

	# Ondulation
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

	# Flip
	if dir.x < 0:
		visual.scale.x = -abs(visual.scale.x)
	else:
		visual.scale.x = abs(visual.scale.x)

	# --- Spawn de la bulle d'air sur la frame de 0 à 0.2s
	var t = anim.current_animation_position

	# détection de boucle (retour au début)
	if t < duration_anim_swim:
		_spawn_air_bubble()

	duration_anim_swim = t

func _spawn_air_bubble():
	var b = air_bubble_scene.instantiate()
	
	# --- Taille de la bulle  ---
	b.scale = Vector2(0.5, 0.5)
	
	get_parent().add_child(b)
	b.global_position = air_spawn.global_position

	# Lance l'anim "air" 
	var b_anim = b.get_node("Path2D/PathFollow2D/AnimationPlayer")
	b_anim.play("air")
