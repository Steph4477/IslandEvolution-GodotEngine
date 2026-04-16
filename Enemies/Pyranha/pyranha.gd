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

	# refresh player
	if player == null or not is_instance_valid(player):
		refresh_player()

	# update target
	target_mod.update()

	# décision simple
	if target != null:
		chase_target()
		play_chase()
	else:
		patrol_mod.process(delta)

		play_swim()

func _on_patrol_timer_timeout():
	patrol_mod.on_timeout()
