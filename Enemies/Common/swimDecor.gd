extends Node2D

@export var speed = 400.0
@export var fish_color = Color(1, 1, 1, 1)

# angle initial
@export var start_angle_deg = 0.0

# variation d’angle aléatoire
@export var angle_range_deg = 60.0   # ex: -30° / +30°

# timer direction
@export var min_change_time = 2.0
@export var max_change_time = 5.0

var air_bubble_scene = preload("res://Effects/Aquatic_breathing/Air_bubble/air_bubble.tscn")

@onready var visual = $Visual
@onready var sprite = $Visual/Sprite
@onready var anim = $AnimationPlayer
@onready var bounds_col = $Bounds/CollisionShape2D
@onready var air_spawn = $Visual/AirSpawn
@onready var timer = $Timer

var dir = Vector2.ZERO
var min_bound = Vector2.ZERO
var max_bound = Vector2.ZERO

var duration_bubble = 0.5

func _ready():
	print(name, " speed = ", speed)

	sprite.modulate = fish_color

	if anim.has_animation("swim"):
		anim.play("swim")

	# direction initiale
	set_random_dir()

	# bounds
	var rect = bounds_col.shape
	var ext = rect.extents
	var center = bounds_col.global_position
	min_bound = center - ext
	max_bound = center + ext

	start_random_timer()

	duration_bubble = anim.current_animation_position

func _physics_process(delta):
	# déplacement
	global_position += dir * speed * delta

	# clamp 
	global_position.x = clamp(global_position.x, min_bound.x, max_bound.x)
	global_position.y = clamp(global_position.y, min_bound.y, max_bound.y)
	
	# Flip (sur Visual)
	if dir.x < 0:
		visual.scale.x = -abs(visual.scale.x)
	else:
		visual.scale.x = abs(visual.scale.x)

	# bulles (début de boucle anim)
	var t = anim.current_animation_position
	if t < duration_bubble:
		spawn_air_bubble()
	duration_bubble = t

# -----------------------
# TIMER
# -----------------------
func _on_timer_timeout():
	set_random_dir()
	start_random_timer()


func start_random_timer():
	timer.wait_time = randf_range(min_change_time, max_change_time)
	timer.start()

# -----------------------
# DIRECTION
# -----------------------
func set_random_dir():
	var angle = randf_range(0.0, 360.0)
	dir = Vector2.RIGHT.rotated(deg_to_rad(angle)).normalized()

# -----------------------
# BULLE
# -----------------------
func spawn_air_bubble():
	var b = air_bubble_scene.instantiate()
	b.scale = Vector2(0.5, 0.5)
	get_parent().add_child(b)
	b.global_position = air_spawn.global_position

	var b_anim = b.get_node("Path2D/PathFollow2D/AnimationPlayer")
	b_anim.play("air")
