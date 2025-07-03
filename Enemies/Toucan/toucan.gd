extends CharacterBody2D

@export var max_hp: int = 20
@export var speed: float = 200.0
@export var patrol_change_interval: float = 2.0
@export var idle_duration: float = 5.0
@export var land_interval: float = 10.0
@export var look_range: float = 300.0
@export var look_duration: float = 1.5
@export var look_cooldown: float = 5.0

@onready var health_bar = $HealthBar/ProgressBar
@onready var timer = $Timer
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite

var pv: int
var is_dead := false
var is_flying := true
var is_landing := false
var landed := false
var patrol_direction := Vector2.ZERO
var player: Node2D
var is_looking := false
var can_look_again := true

func _ready() -> void:
	print("Animations : ", anim.get_animation_list())
	pv = max_hp
	find_and_bind_player()
	start_patrol()

	## Timer pour atterrissage périodique
	#var land_timer := Timer.new()
	#land_timer.wait_time = land_interval
	#land_timer.one_shot = false
	#land_timer.timeout.connect(_on_land_timer_timeout)
	#add_child(land_timer)
	#land_timer.start()
#
	## Timer qui vérifie la présence du joueur
	#var look_timer := Timer.new()
	#look_timer.wait_time = 0.2
	#look_timer.one_shot = false
	#look_timer.timeout.connect(check_player_distance)
	#add_child(look_timer)
	#look_timer.start()

func _physics_process(_delta: float) -> void:
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

func check_player_distance():
	if is_dead or is_looking or not can_look_again or player == null:
		return

	var d = global_position.distance_to(player.global_position)
	if d < look_range:
		await look_at_player()

func look_at_player():
	is_looking = true
	can_look_again = false

	print("👀 Le joueur est proche ! Je regarde.")
	sprite.scale.x = abs(sprite.scale.x) if player.global_position.x > global_position.x else -abs(sprite.scale.x)
	anim.play("look")

	await get_tree().create_timer(look_duration).timeout
	is_looking = false

	# Cooldown avant de pouvoir regarder à nouveau
	await get_tree().create_timer(look_cooldown).timeout
	can_look_again = true

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

#func _on_land_timer_timeout():
	#if not is_flying or is_dead:
		#return
	#is_landing = true
	##await wait_until_on_floor()
	##is_landing = false
	#landed = true
	#is_flying = false
	#await get_tree().create_timer(idle_duration).timeout
	#landed = false
	#is_flying = true
	#change_patrol_direction()
##
##func wait_until_on_floor():
	##while not is_on_floor():
		##await get_tree().process_frame

func on_hit(damage_taken: int):
	pv -= damage_taken
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = pv
	if pv <= 0:
		die()

func die():
	if is_dead:
		return
	is_dead = true
	anim.play("die")
	await anim.animation_finished
	queue_free()

func find_and_bind_player():
	var gs = get_node_or_null("/root/GameManagement/SceneContainer/GameState")
	if gs:
		player = gs.player
		gs.connect("player_updated", Callable(self, "_on_player_changed"))

func _on_player_changed(new_player: Node) -> void:
	player = new_player

func _on_area_2d_body_entered(_body: Node2D) -> void:
	pass  # le toucan est un ami !
