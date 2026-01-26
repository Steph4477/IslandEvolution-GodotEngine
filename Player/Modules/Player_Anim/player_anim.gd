extends Node

var p = null
var anim = null

func setup(player):
	p = player
	anim = p.anim

func play_locked(_name):
	anim.play(_name)
	p.animation_locked = true
	await anim.animation_finished
	p.animation_locked = false

func process():
	# Reprise exacte de ta logique update_animation() (déportée)
	if p.animation_locked or p.is_dead:
		return

	if p.is_swimming_under_water:
		if anim.current_animation != "swim_under_water":
			anim.play("swim_under_water")
		return

	if p.is_swimming:
		if anim.current_animation != "swim":
			anim.play("swim")
		return

	if p.is_on_liana:
		return

	if p.is_hanging:
		return

	if p.climbing_anim != "" and p.velocity.y != 0:
		anim.play(p.climbing_anim)
		return

	if anim.current_animation == "hang":
		return

	if p.is_gazed:
		if anim.current_animation != "walk_gaz":
			anim.play("walk_gaz")
		return

	if p.is_on_floor() and p.is_sprinting and abs(p.velocity.x) > 0.1:
		if anim.current_animation != "sprint":
			anim.play("sprint")
		return

	if p.is_on_floor():
		if p.is_pushing_or_pulling and not p.is_ramping:
			anim.play("push")
			return

		if p.is_ramping:
			if abs(p.velocity.x) > 0.1:
				anim.play("ramp")
			else:
				anim.play("idle")
		else:
			if abs(p.velocity.x) > 0.1:
				if p.is_gazed:
					anim.play("walk_gaz")
				if p.is_web:
					anim.play("web_effect")
				else:
					anim.play("walk")
			else:
				anim.play("idle")
		return

	if p.velocity.y < 0:
		if p.jump_count > 1:
			anim.play("jump2_up")
		else:
			anim.play("jump_up")
	elif p.velocity.y > 0:
		if p.jump_count > 1:
			anim.play("jump2_down")
		else:
			anim.play("jump_down")
