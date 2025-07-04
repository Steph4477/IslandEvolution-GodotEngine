extends CharacterBody2D

@export var speed: float = 200.0
@export var patrol_change_interval: float = 2.0
@export var idle_duration: float = 5.0
@export var land_interval: float = 10.0


@onready var health_bar = $HealthBar/ProgressBar
@onready var timer = $Timer
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite


var is_flying := true
var is_landing := false
var landed := false
var patrol_direction := Vector2.ZERO
var player: Node2D


func _ready() -> void:
	sprite.modulate = Color(1.4, 1.4, 0.2)
	start_patrol()

	# Timer pour atterrissage périodique
	var land_timer := Timer.new()
	land_timer.wait_time = land_interval
	land_timer.one_shot = false
	land_timer.timeout.connect(_on_land_timer_timeout)
	add_child(land_timer)
	land_timer.start()

func _physics_process(delta: float) -> void:
	if is_landing:
		velocity = Vector2(0, 200)
		anim.play("flight")
	elif landed:
		velocity = Vector2.ZERO
		anim.play("idle")
	elif is_flying:
		velocity = patrol_direction * speed
		anim.play("flight")

	# Flip du sprite en fonction de la direction
	if velocity.x != 0:
		sprite.scale.x = abs(sprite.scale.x) if velocity.x > 0 else -abs(sprite.scale.x)

	move_and_slide()

func start_patrol():
	change_patrol_direction()
	timer.wait_time = patrol_change_interval
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func change_patrol_direction():
	var angle = randf() * TAU
	patrol_direction = Vector2(cos(angle), sin(angle)).normalized()

func _on_timer_timeout():
	if is_flying:
		change_patrol_direction()

func _on_land_timer_timeout():
	if not is_flying:
		return
	is_landing = true
	await wait_until_on_floor()
	is_landing = false
	landed = true
	is_flying = false
	await get_tree().create_timer(idle_duration).timeout
	landed = false
	is_flying = true
	change_patrol_direction()
#
func wait_until_on_floor():
	while not is_on_floor():
		await get_tree().process_frame
