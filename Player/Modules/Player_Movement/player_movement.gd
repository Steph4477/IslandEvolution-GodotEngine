extends Node

var p


func setup(player):
	p = player

# ============================================================================
#                                 PROCESS
# ============================================================================

func process(delta, was_on_floor):
	process_harpooned(delta)

	if not p.can_move:
		return

	update_push_pull_state()

	process_climb()
	process_liana(delta)
	update_jump(delta)

	move_horizontal()

	process_swim(delta)
	process_swim_under_water(delta)

	process_hang_swing(delta)

	track_fall_speed(was_on_floor)

func post_physics(was_on_floor):
	if p.is_harpooned:
		return

	apply_fall_damage(was_on_floor)
	process_wall_jump_input()

# ============================================================================
#                           MOUVEMENTS
# ============================================================================
func update_push_pull_state():
	p.is_pushing_or_pulling = p.can_push_pull and Input.is_action_pressed("interact")

func move_horizontal():
	if p.is_on_liana:
		p.velocity.x = 0
		return

	var dir = Input.get_action_strength(p.INPUT["right"]) - Input.get_action_strength(p.INPUT["left"])
	var current_speed = p.speed

	if p.is_sprinting:
		current_speed = p.speed * 1.5

	p.velocity.x = dir * current_speed

	if dir != 0 and not p.is_pushing_or_pulling:
		p.sprite.scale.x = abs(p.sprite.scale.x)

		if dir > 0:
			p.sprite.flip_h = false
		else:
			p.sprite.flip_h = true

# ============================================================================
#                                CLIMB
# ============================================================================
func process_climb():
	# pas en zone => on sort proprement du climb/hang
	if not p.can_climb:
		if p.climbing_anim != "" or p.is_hanging:
			p.climbing_anim = ""
			p.is_hanging = false
			p.hang_timer = 0.0
			p.sprite.rotation_degrees = 0
			p.velocity.y = 0
			if p.anim.current_animation == "hang":
				p.anim.play("idle")
		return

	# on est en zone climb : on initialise le mode
	if p.climbing_anim == "":
		p.climbing_anim = "climb_coco"
		p.anim.play("hang")
		p.velocity.y = 0
		p.is_hanging = true

	# input : ui_up OU action "climb" si tu l'utilises
	var up_pressed = Input.is_action_pressed("ui_up") 

	if up_pressed:
		if not p.anim.is_playing() or p.anim.current_animation != p.climbing_anim:
			p.anim.play(p.climbing_anim)
		p.velocity.y = -p.climb_speed
		p.is_hanging = false
	else:
		if p.anim.current_animation != "hang":
			p.anim.play("hang")
		p.velocity.y = 0
		p.is_hanging = true


func process_hang_swing(delta):
	if p.is_hanging:
		p.hang_timer += delta
		var swing = sin(p.hang_timer * 2.0) * 5
		p.sprite.rotation_degrees = swing
	else:
		p.sprite.rotation_degrees = 0
		p.hang_timer = 0.0

# ============================================================================
#                                LIANA
# ============================================================================
func process_liana(_delta):
	if not p.is_on_liana or p.current_liana == null or p.did_double_jump:
		return

	p.is_swimming = false
	p.is_swimming_under_water = false

	p.velocity = Vector2.ZERO
	hand_to_grip()

	var left = Input.is_action_pressed("ui_left")
	var right = Input.is_action_pressed("ui_right")
	if p.current_liana.has_node("Pivot"):
		if left:
			p.current_liana.angle_direction = 1
		elif right:
			p.current_liana.angle_direction = -1
		else:
			p.current_liana.angle_direction = 0

	if Input.is_action_just_pressed("jump"):
		var power = 900
		var angle_deg = p.current_liana.get_node("Pivot").rotation_degrees
		p.velocity = Vector2(0, -power).rotated(deg_to_rad(angle_deg))
		p.current_liana.expect_exit = true
		p.current_liana.on_player_detach()
		p.current_liana.disable_collision_temporarily(0.3)
		detach_to_liana()

func hand_to_grip():
	var grip = p.current_liana.get_node("Pivot/Grip")
	var hand = p.get_node("Node2D/AttachMarker")
	var delta = grip.global_position - hand.global_position
	p.global_position += delta

func attach_to_liana(liana):
	p.is_on_liana = true
	p.current_liana = liana
	if p.current_liana.has_method("on_player_attach"):
		p.current_liana.on_player_attach()

	p.velocity = Vector2.ZERO
	hand_to_grip()
	p.anim.play("climb")

func detach_to_liana():
	p.is_on_liana = false
	p.current_liana = null
# ============================================================================
#                           JUMP / WALL JUMP
# ============================================================================
func update_jump(delta):
	if p.is_harpooned or not p.can_move:
		p.is_jumping = false
		p.jump_count = 0
		return

	# Bloque toute logique de saut sous l'eau (surface + underwater)
	if p.is_swimming or p.is_swimming_under_water:
		p.is_jumping = false
		return

	if p.climbing_anim != "":
		p.is_jumping = false
		return

	if p.is_on_floor():
		p.jump_count = 0
		p.is_jumping = false

	p.max_jump_count = 1
	if p.game_state and p.game_state.double_jump_unlocked:
		p.max_jump_count = 2

	if Input.is_action_just_pressed(p.INPUT["jump"]) and p.jump_count < p.max_jump_count:
		p.velocity.y = p.jump_force
		p.is_ramping = false
		p.jump_count += 1
		p.is_jumping = true

	if not p.is_on_floor():
		p.is_jumping = true
		if not p.is_ramping:
			p.velocity.y += p.gravity * p.gravity_factor * delta


func process_wall_jump_input():
	if p.is_harpooned:
		return

	if p.is_on_floor():
		return
	if p.is_on_liana:
		return
	if p.is_swimming or p.is_swimming_under_water:
		return

	if p.is_on_wall() and Input.is_action_just_pressed("jump"):
		wall_jump()

func wall_jump():
	var normal = p.get_wall_normal()
	var dir = -normal.x

	if dir == 0:
		if p.sprite.scale.x >= 0:
			dir = -1
		else:
			dir = 1

	p.velocity.y = p.jump_force
	p.velocity.x = dir * p.speed

# ============================================================================
#                                SWIM
# ============================================================================
func process_swim(delta):
	if p.is_swimming:
		p.swim_timer += delta
		var h = Input.get_action_strength(p.INPUT["right"]) - Input.get_action_strength(p.INPUT["left"])
		p.velocity.x = h * p.speed * 0.5 + p.water_current.x
		p.velocity.y = 0

		if h != 0:
			p.sprite.scale.x = abs(p.sprite.scale.x)

			if h > 0:
				p.sprite.flip_h = false
			else:
				p.sprite.flip_h = true

func process_swim_under_water(delta):
	if p.is_swimming_under_water:
		p.swim_timer += delta
		var h = Input.get_action_strength(p.INPUT["right"]) - Input.get_action_strength(p.INPUT["left"])
		var v = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

		p.velocity.x = h * p.speed * 0.5 + p.water_current.x
		p.velocity.y = v * p.speed * 0.35

		if h != 0:
			p.sprite.scale.x = abs(p.sprite.scale.x)

			if h > 0:
				p.sprite.flip_h = false
			else:
				p.sprite.flip_h = true

# ============================================================================
#                           FALL DAMAGE
# ============================================================================
func track_fall_speed(was_on_floor):
	if not p.fall_damage_enabled:
		return

	if p.is_swimming or p.is_swimming_under_water or p.is_on_liana or p.climbing_anim != "" or p.is_hanging or p.is_camouflaged:
		p.fall_speed_track = 0
		return

	if not was_on_floor:
		if p.velocity.y > p.fall_speed_track:
			p.fall_speed_track = p.velocity.y
	else:
		p.fall_speed_track = 0

func apply_fall_damage(was_on_floor):
	if not p.fall_damage_enabled:
		return
	if p.is_dead:
		return

	if not was_on_floor and p.is_on_floor():
		var impact_speed = p.fall_speed_track
		p.fall_speed_track = 0

		if impact_speed <= p.fall_safe_limit:
			return

		var dmg = p.fall_damage_min

		if impact_speed >= p.fall_speed_max:
			dmg = p.fall_damage_max
		else:
			var range_speed = p.fall_speed_max - p.fall_safe_limit
			var over_speed = impact_speed - p.fall_safe_limit
			dmg += (p.fall_damage_max - p.fall_damage_min) * over_speed / range_speed

		dmg = int(dmg)
		if dmg <= 0:
			return

		# Applique les dégâts + anim onhit
		p.damage_mod.on_hit(dmg)

# ============================================================================
#                                HARPOONED
# ============================================================================

func process_harpooned(delta):
	if not p.is_harpooned:
		return

	p.is_hanging = false
	p.is_on_liana = false
	p.climbing_anim = ""
	p.is_jumping = false
	p.is_ramping = false
	p.is_sprinting = false
	p.jump_count = 0

	p.velocity.x = 0

	if p.is_on_floor():
		p.velocity.y = 0
	else:
		p.velocity.y += p.gravity * p.gravity_factor * delta
