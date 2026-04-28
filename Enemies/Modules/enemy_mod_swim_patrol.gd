extends RefCounted
class_name EnemyModSwimPatrol

var e = null

func setup(enemy):
	e = enemy
	randomize()
	pick_direction()

func process(_delta):
	e.velocity = e.dir * e.swim_speed
	e.move_and_slide()
	e.handle_swim_collision()

	if e.dir.x < 0:
		e.rotator.scale.x = -1
	elif e.dir.x > 0:
		e.rotator.scale.x = 1

func on_timeout():
	pick_direction()

func pick_direction():
	e.dir = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()

	if e.dir == Vector2.ZERO:
		e.dir = Vector2.RIGHT
