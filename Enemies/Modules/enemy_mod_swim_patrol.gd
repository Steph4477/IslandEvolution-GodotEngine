extends RefCounted
class_name EnemyModSwimPatrol

var e = null

func setup(enemy):
	e = enemy
	randomize()
	pick_direction()

func process(delta):
	e.velocity = e.dir * e.swim_speed
	e.move_and_slide()

	if e.dir.x < 0:
		e.rotator.scale.x = -1
	elif e.dir.x > 0:
		e.rotator.scale.x = 1

	clamp_bounds()

func on_timeout():
	pick_direction()

func pick_direction():
	e.dir = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()

func clamp_bounds():
	var pos = e.global_position

	if pos.x < e.min_bound.x:
		pos.x = e.min_bound.x
		e.dir.x = abs(e.dir.x)

	if pos.x > e.max_bound.x:
		pos.x = e.max_bound.x
		e.dir.x = -abs(e.dir.x)

	if pos.y < e.min_bound.y:
		pos.y = e.min_bound.y
		e.dir.y = abs(e.dir.y)

	if pos.y > e.max_bound.y:
		pos.y = e.max_bound.y
		e.dir.y = -abs(e.dir.y)

	e.global_position = pos
