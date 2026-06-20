extends EnemyGroundBase
class_name EnemyMelee

@export var balance_id = "snake_melee"

var melee_distance = 0
var attack_cooldown = 1.0
var animation_attack = "attack"
var animation_walk = "walk"

var melee_mod = EnemyModMelee.new()


func _ready():
	super._ready()

	max_hp = GameBalance.ENEMY_HP[balance_id]
	hp = max_hp
	damage = GameBalance.ENEMY_DAMAGE[balance_id]
	speed = GameBalance.ENEMY_SPEED[balance_id]
	melee_distance = GameBalance.ENEMY_MELEE_DISTANCE[balance_id]
	attack_cooldown = GameBalance.ENEMY_COOLDOWN[balance_id]
	animation_attack = GameBalance.ENEMY_ANIMATION_ATTACK[balance_id]
	animation_walk = GameBalance.ENEMY_ANIMATION_WALK[balance_id]

	attack_anim_name = animation_attack
	attack_timer.wait_time = attack_cooldown

	melee_mod.setup(self)


func _physics_process(delta):
	if is_dead:
		return

	apply_gravity(delta)
	target_player()
	flip()

	melee_mod.update_state()

	if in_melee:
		velocity.x = 0
	elif distance <= attack_range:
		move_to_target()
	else:
		velocity.x = 0
		play_idle()

	move_and_slide()


func move_to_target():
	if dx > stop_distance:
		velocity.x = speed

		if anim.current_animation != animation_walk:
			anim.play(animation_walk)

	elif dx < -stop_distance:
		velocity.x = -speed

		if anim.current_animation != animation_walk:
			anim.play(animation_walk)

	else:
		velocity.x = 0
		play_idle()


func _on_attack_timer_timeout():
	melee_mod.on_timer_timeout()
