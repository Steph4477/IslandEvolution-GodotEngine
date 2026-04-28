extends CharacterBody2D

@export var speed = 220.0
@export var fish_color = Color(1, 1, 1, 1)

@export var start_angle_deg = 0.0
@export var angle_range_deg = 35.0

@export var min_change_time = 2.0
@export var max_change_time = 5.0
@export var use_bubbles = true

var air_bubble_scene = preload("res://Effects/Aquatic_breathing/Air_bubble/air_bubble.tscn")

@onready var visual = $Visual
@onready var sprite = $Visual/Sprite
@onready var anim = $AnimationPlayer
@onready var air_spawn = $Visual/AirSpawn
@onready var timer = $Timer

var dir = Vector2.ZERO
var duration_bubble = 0.5

func _ready():
	sprite.modulate = fish_color

	if anim.has_animation("swim"):
		anim.play("swim")

	set_start_dir()
	start_random_timer()

	duration_bubble = anim.current_animation_position

func _physics_process(_delta):
	velocity = dir * speed
	move_and_slide()
	handle_collision()

	if dir.x < 0:
		visual.scale.x = -1
	elif dir.x > 0:
		visual.scale.x = 1

	if use_bubbles:
		var t = anim.current_animation_position
		if t < duration_bubble:
			spawn_air_bubble()
		duration_bubble = t

func _on_timer_timeout():
	pick_soft_new_dir()
	start_random_timer()

func start_random_timer():
	timer.wait_time = randf_range(min_change_time, max_change_time)
	timer.start()

func set_start_dir():
	dir = Vector2.RIGHT.rotated(deg_to_rad(start_angle_deg)).normalized()

	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT

func pick_soft_new_dir():
	var current_angle = rad_to_deg(dir.angle())
	var new_angle = randf_range(
		current_angle - angle_range_deg,
		current_angle + angle_range_deg
	)

	dir = Vector2.RIGHT.rotated(deg_to_rad(new_angle)).normalized()

	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT

func handle_collision():
	if get_slide_collision_count() == 0:
		return

	var collision = get_slide_collision(0)
	var normal = collision.get_normal()

	dir = dir.bounce(normal).normalized()

	if dir == Vector2.ZERO:
		dir = Vector2.LEFT

	velocity = Vector2.ZERO

func spawn_air_bubble():
	var b = air_bubble_scene.instantiate()
	b.scale = Vector2(0.5, 0.5)
	get_parent().add_child(b)
	b.global_position = air_spawn.global_position

	var b_anim = b.get_node("Path2D/PathFollow2D/AnimationPlayer")
	b_anim.play("air")
