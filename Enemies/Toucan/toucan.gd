extends CharacterBody2D

@export var max_hp = 20
@export var speed = 200.0
@export var patrol_change_interval = 2.0
@export var idle_duration = 5.0
@export var land_interval = 10.0

@onready var timer = $Timer
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite

var pv
var is_dead = false
var is_flying = true
var is_landing = false
var landed = false
var patrol_direction = Vector2.ZERO
var player
var is_looking = false
var can_look_again = true

func _ready():
	pv = max_hp
	find_and_bind_player()
	start_patrol()

func _physics_process(_delta):
	if is_dead or player == null or is_looking:
		return

	# Mouvement selon l’état
	if is_landing:
		velocity = Vector2(0, 200)
		anim.play("flight")
	elif landed:
		velocity = Vector2.ZERO
		anim.play("idle")
	else:
		velocity = patrol_direction * speed
		anim.play("flight")

	# Flip du sprite
	if velocity.x != 0:
		sprite.scale.x = abs(sprite.scale.x) if velocity.x > 0 else -abs(sprite.scale.x)

	move_and_slide()

func start_patrol():
	change_patrol_direction()
	timer.wait_time = patrol_change_interval
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)
	timer.start()

func change_patrol_direction():
	var angle = randf() * TAU
	patrol_direction = Vector2(cos(angle), sin(angle)).normalized()

func _on_timer_timeout():
	if is_flying:
		change_patrol_direction()

func find_and_bind_player():
	var gs = get_node_or_null("/root/GameState")
	if gs:
		player = gs.player
		if not gs.is_connected("player_updated", Callable(self, "_on_player_changed")):
			gs.connect("player_updated", Callable(self, "_on_player_changed"))

func _on_player_changed(new_player):
	player = new_player
