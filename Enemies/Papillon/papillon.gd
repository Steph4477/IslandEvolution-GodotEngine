extends CharacterBody2D

@export var speed: float = 100.0
@export var patrol_change_interval: float = 2.0
@export var butterfly_color: Color = Color(1, 1, 1, 1)
@export var shader: Shader = preload("res://Enemies/Papillon/papillon_recolor.gdshader")

@onready var timer = $Timer
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite

var patrol_direction := Vector2.ZERO

func _ready() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("target_color", butterfly_color)
	mat.set_shader_parameter("mix_strength", 0.8)  # 1.0 = couleur vive, 0.0 = texture originale

	sprite.material = mat
	
	await get_tree().process_frame  # 👈 Attendre que l'instance soit bien initialisée
	sprite.modulate = butterfly_color
	start_patrol()

func _physics_process(delta: float) -> void:
	velocity = patrol_direction * speed
	anim.play("flight")

	# Flip du sprite selon la direction
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
	change_patrol_direction()
