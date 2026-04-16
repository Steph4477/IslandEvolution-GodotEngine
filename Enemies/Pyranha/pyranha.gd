extends EnemySwimBase

var patrol = EnemyModSwimPatrol.new()

func _ready():
	super._ready()

	patrol.setup(self)
	patrol.start()

func _physics_process(delta):
	if is_dead:
		return

	patrol.update()
	move_swim(delta)
	update_flip()

func _on_patrol_timer_timeout():
	patrol.on_timer_timeout()
