extends EnemySwimBase
class_name Pyranha

var target_mod
var patrol_mod

func _ready():
	super._ready()

	target_mod = EnemyModTarget.new()
	target_mod.setup(self)

	patrol_mod = EnemyModSwimPatrol.new()
	patrol_mod.setup(self)

func _physics_process(delta):
	if is_dead:
		return

	if player == null or not is_instance_valid(player):
		refresh_player()

	target_mod.update()

	if in_melee: 
		play_attack()
		return

	if target != null:
		chase_target()
		play_chase()
	else:
		patrol_mod.process(delta)
		play_swim()

func attack():
	if is_dead:
		return

	play_attack()

	if player != null and is_instance_valid(player):
		player.damage_mod.on_hit(damage)

func _on_patrol_timer_timeout():
	patrol_mod.on_timeout()

func _on_attack_zone_body_entered(body):
	if is_dead:
		return

	if body.is_in_group("Player"):
		in_melee = true
		attack()
		attack_timer.start()

func _on_attack_zone_body_exited(body):
	if body.is_in_group("Player"):
		in_melee = false
		attack_timer.stop()

func _on_attack_timer_timeout():
	if is_dead:
		return

	if not in_melee:
		return

	attack()
	attack_timer.start()
