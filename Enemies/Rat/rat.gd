extends EnemyGroundBase

@export var melee_distance = 70.0

var melee_mod = EnemyModMelee.new()

func _ready():
	max_hp = 300
	damage = 100
	speed = 400
	attack_range = 500
	stop_distance = 40
	gravity = 2000
	attack_anim_name = "attack"

	super._ready()
	setup_common_refs()

	melee_mod.setup(self)

	attack_timer.stop()

func _physics_process(delta):
	apply_gravity(delta)

	if is_dead or is_attacking:
		velocity.x = 0
		move_and_slide()
		return

	target_player()

	if player == null:
		velocity.x = 0

		if anim.current_animation != "idle":
			anim.play("idle")

		move_and_slide()
		return

	flip()
	melee_mod.update_state()

	if in_melee:
		velocity.x = 0

		if anim.current_animation != "idle":
			anim.play("idle")
	else:
		move_to_target()

	move_and_slide()

func die():
	in_melee = false
	super.die()

func _on_attack_timer_timeout():
	melee_mod.on_timer_timeout()
