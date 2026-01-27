extends Node

var p

func setup(player):
	p = player

func process():
	if p == null:
		return

	if p.animation_locked or p.is_dead:
		return

	# --- Underwater swim ---
	if p.is_swimming_under_water:
		if p.anim.current_animation != "swim_under_water":
			p.anim.play("swim_under_water")
		return

	# --- Surface swim ---
	if p.is_swimming:
		if p.anim.current_animation != "swim":
			p.anim.play("swim")
		return

	# --- Liana / Hang / Climb locks ---
	if p.is_on_liana:
		return

	if p.is_hanging:
		return

	if p.climbing_anim != "" and p.velocity.y != 0:
		p.anim.play(p.climbing_anim)
		return

	if p.anim.current_animation == "hang":
		return

	# --- Gaz override ---
	if p.is_gazed:
		if p.anim.current_animation != "walk_gaz":
			p.anim.play("walk_gaz")
		return

	# --- Sprint ---
	if p.is_on_floor() and p.is_sprinting and abs(p.velocity.x) > 0.1:
		if p.anim.current_animation != "sprint":
			p.anim.play("sprint")
		return

	# --- Ground locomotion ---
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

		# walk / idle
		if abs(p.velocity.x) > 0.1:
			# garde exactement ta logique (gaz/web)
			if p.is_gazed:
				p.anim.play("walk_gaz")
			if p.is_web:
				p.anim.play("web_effect")
			else:
				p.anim.play("walk")
		else:
			p.anim.play("idle")
		return

	# --- Air locomotion (jump/fall) ---
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
