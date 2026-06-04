extends Node

var p
var is_interacting = false

func setup(player):
	p = player

func set_interact(value):
	is_interacting = value

func process():
	if p == null:
		return

	if p.is_dead:
		return

	if p.is_harpooned:
		if p.anim.current_animation != "harpooned":
			p.anim.play("harpooned")
		return

	if is_interacting:
		if p.anim.current_animation != "push":
			p.anim.play("push")
		return

	if p.is_headbutting:
		if p.anim.current_animation != "headbutt_swim":
			p.anim.play("headbutt_swim")
		return

	if p.is_kicking:
		if p.anim.current_animation != "kick":
			p.anim.play("kick")
		return

	if p.animation_locked:
		return

	if p.is_swimming_under_water:
		if p.anim.current_animation != "swim_under_water":
			p.anim.play("swim_under_water")
		return

	if p.is_swimming:
		if p.anim.current_animation != "swim":
			p.anim.play("swim")
		return

	if p.is_on_liana:
		return

	if p.is_hanging:
		return

	if p.climbing_anim != "" and p.velocity.y != 0:
		p.anim.play(p.climbing_anim)
		return

	if p.anim.current_animation == "hang":
		return

	if p.is_gazed:
		if p.anim.current_animation != "walk_gaz":
			p.anim.play("walk_gaz")
		return

	if p.is_on_floor() and p.is_sprinting and abs(p.velocity.x) > 0.1:
		if p.anim.current_animation != "sprint":
			p.anim.play("sprint")
		return

	if p.is_jump_clacing:
		if p.anim.current_animation != "jump_clac":
			p.anim.play("jump_clac")
		return

	if p.is_on_floor():
		if p.is_pushing_or_pulling and not p.is_ramping:
			p.anim.play("push")
			return

		if p.is_ramping:
			if abs(p.velocity.x) > 0.1:
				p.anim.play("ramp")
			else:
				p.anim.play("idle")
			return

		if abs(p.velocity.x) > 0.1:
			if p.is_gazed:
				p.anim.play("walk_gaz")
			if p.is_web:
				p.anim.play("web_effect")
			else:
				p.anim.play("walk")
		else:
			p.anim.play("idle")
		return

	if p.velocity.y < 0:
		if p.jump_count > 1:
			p.anim.play("jump2_up")
		else:
			p.anim.play("jump_up")
	elif p.velocity.y > 0:
		if p.jump_count > 1:
			p.anim.play("jump2_down")
		else:
			p.anim.play("jump_down")
