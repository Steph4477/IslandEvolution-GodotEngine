extends EnemyBase
class_name EnemySwimBase

@export var swim_speed = 120.0
@export var chase_speed = 160.0
@export var detection_range = 250.0
@export var min_change_time = 1.5
@export var max_change_time = 3.5

var dir = Vector2.ZERO
var dx = 0
var distance = 999999
var target = null

var rotator
var patrol_mod

func _ready():
	super._ready()

	rotator = $Rotator
	patrol_timer = $PatrolTimer

func setup_patrol():
	patrol_mod = EnemyModSwimPatrol.new()
	patrol_mod.setup(self)
	patrol_mod.on_timeout()

	if patrol_timer:
		patrol_timer.wait_time = randf_range(min_change_time, max_change_time)
		patrol_timer.start()

func refresh_swim_target():
	target = null

	if player == null:
		return

	if player.is_dead:
		return

	if not player.is_swimming_under_water:
		return

	distance = global_position.distance_to(player.global_position)

	if distance <= detection_range:
		target = player

func process_swim_state(delta):
	if target != null:
		chase_target()
		play_chase()
	else:
		if patrol_mod:
			patrol_mod.process(delta)
		play_swim()

func restart_patrol_timer():
	if patrol_timer:
		patrol_timer.wait_time = randf_range(min_change_time, max_change_time)
		patrol_timer.start()

func handle_swim_collision():
	if get_slide_collision_count() == 0:
		return

	var collision = get_slide_collision(0)
	var normal = collision.get_normal()

	dir = dir.bounce(normal).normalized()

	if dir == Vector2.ZERO:
		dir = -velocity.normalized()

	if dir == Vector2.ZERO:
		dir = Vector2.LEFT

	velocity = Vector2.ZERO

	if dir.x < 0:
		rotator.scale.x = -1
	elif dir.x > 0:
		rotator.scale.x = 1

func chase_target():
	if target == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var target_position = target.global_position

	if target.has_node("TurnAxis"):
		target_position = target.get_node("TurnAxis").global_position

	var to_target = target_position - global_position

	if to_target == Vector2.ZERO:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var chase_dir = to_target.normalized()
	velocity = chase_dir * chase_speed
	move_and_slide()
	handle_swim_collision()

	if chase_dir.x < 0:
		rotator.scale.x = -1
	elif chase_dir.x > 0:
		rotator.scale.x = 1

func play_swim():
	if anim:
		if anim.current_animation != "swim":
			anim.play("swim")

func play_chase():
	if anim:
		if anim.current_animation != "chase":
			anim.play("chase")

func play_attack():
	if anim:
		if anim.current_animation != "attack":
			anim.play("attack")
