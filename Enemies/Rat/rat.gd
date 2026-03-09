extends EnemyGroundBase

@export var sprint_loot_scene = preload("res://Player/Skills/Sprint/Sprint.tscn")
@export var melee_distance = 70.0

@onready var health_bar = $HealthBar/ProgressBar
@onready var sprite = $Rotator/Sprite2D
@onready var anim = $Rotator/AnimationPlayer
@onready var rotator = $Rotator
@onready var attack_timer = $Timer
@onready var spawn_point = $SpawnPoint

var melee_mod = EnemyModMelee.new()

func _ready():
	max_hp = 300
	damage = 100
	speed = 400
	attack_range = 500
	stop_distance = 40
	gravity = 2000

	melee_mod.setup(self)

	super._ready()

	attack_timer.stop()

func _physics_process(delta):
	apply_gravity(delta)

	if is_dead or is_attacking:
		velocity.x = 0
		move_and_slide()
		return

	if player:
		target_player()
		flip()
		melee_mod.update_state()

		if in_melee:
			velocity.x = 0
			if anim.current_animation != "idle":
				anim.play("idle")
		else:
			move_to_target()
	else:
		velocity.x = 0
		if anim.current_animation != "idle":
			anim.play("idle")

	move_and_slide()

func move_to_target():
	if distance < attack_range and dx > stop_distance:
		velocity.x = speed
		if anim.current_animation != "walk":
			anim.play("walk")
	elif distance < attack_range and dx < -stop_distance:
		velocity.x = -speed
		if anim.current_animation != "walk":
			anim.play("walk")
	else:
		velocity.x = 0
		if anim.current_animation != "idle":
			anim.play("idle")

func attack():
	if is_dead:
		return

	if is_attacking:
		return

	is_attacking = true
	velocity.x = 0
	anim.play("attack")
	player.damage_mod.on_hit(damage)
	await anim.animation_finished
	is_attacking = false

func die():
	is_dead = true
	in_melee = false
	attack_timer.stop()
	velocity = Vector2.ZERO
	anim.play("die")
	await anim.animation_finished

	var loot = sprint_loot_scene.instantiate()
	get_parent().add_child(loot)
	loot.global_position = spawn_point.global_position

	queue_free()

func _on_timer_timeout():
	melee_mod.on_timer_timeout()
