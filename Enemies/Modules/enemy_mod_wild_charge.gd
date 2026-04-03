extends RefCounted
class_name EnemyModWildCharge

var enemy = null
var dust_instance = null
var smoke_instance = null


func setup(parent_enemy):
	enemy = parent_enemy


func update(delta):
	if enemy == null:
		return

	if enemy.charge_cooldown_left > 0.0:
		enemy.charge_cooldown_left -= delta

	if enemy.is_charging:
		enemy.velocity.x = enemy.charge_dir * enemy.charge_speed
		enemy.charge_time -= delta

		update_dust()
		update_smoke()

		if enemy.charge_time <= 0.0:
			stop_charge()
		return

	maybe_start_charge()


func maybe_start_charge():
	if enemy == null:
		return

	if enemy.is_dead:
		return

	if enemy.is_attacking:
		return

	if enemy.in_melee:
		return

	if enemy.is_charging:
		return

	if enemy.charge_cooldown_left > 0.0:
		return

	var jumping = enemy.get("is_jumping")
	if jumping == true:
		return

	var shooting = enemy.get("is_shooting")
	if shooting == true:
		return

	var hit_locked = enemy.get("hit_locked")
	if hit_locked == true:
		return

	if enemy.horiz_distance < enemy.charge_min_range:
		return

	if enemy.horiz_distance > enemy.charge_max_range:
		return

	start_charge()


func start_charge():
	if enemy == null:
		return

	enemy.is_charging = true
	enemy.charge_time = enemy.charge_duration

	enemy.charge_dir = 1
	if enemy.rotator.scale.x < 0:
		enemy.charge_dir = -1

	enemy.velocity.y = 0

	var anim_name = enemy.get("charge_animation_name")
	if anim_name == null or anim_name == "":
		anim_name = "run"

	if enemy.anim.current_animation != anim_name:
		enemy.anim.play(anim_name)

	spawn_dust()
	spawn_smoke()


func stop_charge():
	if enemy == null:
		return

	enemy.is_charging = false
	enemy.charge_cooldown_left = enemy.charge_cooldown
	enemy.velocity.x = 0

	clear_dust()
	clear_smoke()


func cancel_charge():
	if enemy == null:
		return

	enemy.is_charging = false
	enemy.charge_time = 0.0
	enemy.velocity.x = 0

	clear_dust()
	clear_smoke()


func spawn_dust():
	if enemy == null:
		return

	var dust_scene = enemy.get("dust_scene")
	if dust_scene == null:
		return

	if dust_instance != null:
		dust_instance.queue_free()
		dust_instance = null

	dust_instance = dust_scene.instantiate()
	enemy.get_parent().add_child(dust_instance)

	var dust_origin = enemy.get("dust_origin")
	if dust_origin == null:
		dust_origin = enemy.get_node_or_null("Rotator/DustOrigin")

	if dust_origin != null:
		dust_instance.global_position = dust_origin.global_position
	else:
		dust_instance.global_position = enemy.global_position

	dust_instance.scale.x = enemy.rotator.scale.x

	var dust_anim = dust_instance.get_node_or_null("AnimationPlayer")
	if dust_anim != null:
		dust_anim.play("fade")


func update_dust():
	if dust_instance == null:
		return

	if not is_instance_valid(dust_instance):
		dust_instance = null
		return

	var dust_origin = enemy.get("dust_origin")
	if dust_origin == null:
		dust_origin = enemy.get_node_or_null("Rotator/DustOrigin")

	if dust_origin != null:
		dust_instance.global_position = dust_origin.global_position

	dust_instance.scale.x = enemy.rotator.scale.x


func clear_dust():
	if dust_instance != null:
		dust_instance.queue_free()
		dust_instance = null


func spawn_smoke():
	if enemy == null:
		return

	var smoke_scene = enemy.get("smoke_scene")
	if smoke_scene == null:
		return

	if smoke_instance != null:
		smoke_instance.queue_free()
		smoke_instance = null

	smoke_instance = smoke_scene.instantiate()
	enemy.get_parent().add_child(smoke_instance)

	var smoke_spawn = enemy.get("smoke_spawn")
	if smoke_spawn == null:
		smoke_spawn = enemy.get_node_or_null("Rotator/SmokeSpawn")

	if smoke_spawn != null:
		smoke_instance.global_position = smoke_spawn.global_position
	else:
		smoke_instance.global_position = enemy.global_position

	smoke_instance.scale.x = enemy.rotator.scale.x

	var smoke_anim = smoke_instance.get_node_or_null("AnimationPlayer")
	smoke_anim.play("fade")


func update_smoke():
	if smoke_instance == null:
		return

	if not is_instance_valid(smoke_instance):
		smoke_instance = null
		return

	var smoke_spawn = enemy.get("smoke_spawn")
	if smoke_spawn == null:
		smoke_spawn = enemy.get_node_or_null("Rotator/SmokeSpawn")

	if smoke_spawn != null:
		smoke_instance.global_position = smoke_spawn.global_position

	smoke_instance.scale.x = enemy.rotator.scale.x


func clear_smoke():
	if smoke_instance != null:
		smoke_instance.queue_free()
		smoke_instance = null
