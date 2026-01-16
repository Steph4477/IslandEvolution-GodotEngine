extends Node2D

@export var speed = 400.0
@export var fish_color = Color(1, 1, 1, 1)

@export var dir_x = 1.0
@export var dir_y = 0.3

var air_bubble_scene = preload("res://Levels/Lvl4/Environement/Aquatic_breathing/Air_bubble/air_bubble.tscn")

@onready var visual = $Visual
@onready var sprite = $Visual/Sprite
@onready var anim = $AnimationPlayer
@onready var bounds_col = $SwimBounds/CollisionShape2D
@onready var air_spawn = $Visual/AirSpawn

var dir = Vector2.ZERO
var min_bound = Vector2.ZERO
var max_bound = Vector2.ZERO

var duration_bubble = 0.5

func _ready():
	sprite.modulate = fish_color

	if anim.has_animation("swim"):
		anim.play("swim")

	dir = Vector2(dir_x, dir_y).normalized()

	# Calcul de la position dans la zone de patrouille
	var rect = bounds_col.shape                 # RectangleShape2D
	var ext = rect.extents                     # Demi-taille du rectangle (largeur/2, hauteur/2)
	var center = bounds_col.global_position    # Centre du rectangle dans la scène
	min_bound = center - ext                   # Coin haut-gauche du rectangle
	max_bound = center + ext                   # Coin bas-droit du rectangle

func _physics_process(delta):
	# Déplacement
	global_position += dir * speed * delta

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
	if t < duration_bubble:
		_spawn_air_bubble()

	duration_bubble = t

func _spawn_air_bubble():
	var b = air_bubble_scene.instantiate()
	
	# --- Taille de la bulle  ---
	b.scale = Vector2(0.5, 0.5)
	
	get_parent().add_child(b)
	b.global_position = air_spawn.global_position

	# Lance l'anim "air" 
	var b_anim = b.get_node("Path2D/PathFollow2D/AnimationPlayer")
	b_anim.play("air")
