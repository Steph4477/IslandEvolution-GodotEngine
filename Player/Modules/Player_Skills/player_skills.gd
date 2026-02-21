extends Node

var p

func setup(player):
	p = player

# ============================================================================
#                                 PROCESS
# ============================================================================

func process(delta):
	process_ramp()
	process_sprint(delta)
	process_camouflage()

# ============================================================================
#                                 RAMP
# ============================================================================

func process_ramp():
	if p.can_ramp and Input.is_action_just_pressed(p.INPUT["ramp"]) and p.is_on_floor() and not p.ramp_locked:
		p.ramp_locked = true
		p.is_ramping = not p.is_ramping

		if p.is_ramping:
			p.popups_mod.show_info_popup("🧎 Rampe activée !")
			p.get_node("ColStand").disabled = true
			p.get_node("ColRamp").disabled = false
		else:
			p.popups_mod.show_info_popup("🚶 Rampe désactivée !")
			p.get_node("ColStand").disabled = false
			p.get_node("ColRamp").disabled = true

		await p.get_tree().create_timer(0.2).timeout
		p.ramp_locked = false

	if p.is_ramping:
		var rdir = Input.get_action_strength(p.INPUT["right"]) - Input.get_action_strength(p.INPUT["left"])
		p.velocity.x = rdir * p.speed * 0.4
		p.velocity.y += p.gravity * p.gravity_factor * p.get_physics_process_delta_time()

# ============================================================================
#                                 SPRINT
# ============================================================================

func process_sprint(delta):
	if not p.game_state:
		return

	if not p.game_state.sprint_unlocked:
		p.is_sprinting = false
		return

	if p.is_swimming or p.is_swimming_under_water or p.is_ramping or p.is_on_liana:
		p.is_sprinting = false
		if p.game_state.sprint_stamina < p.game_state.sprint_stamina_max:
			p.game_state.sprint_stamina += p.game_state.sprint_stamina_regen * delta
			if p.game_state.sprint_stamina > p.game_state.sprint_stamina_max:
				p.game_state.sprint_stamina = p.game_state.sprint_stamina_max
		p.game_state.speed_bar.update_speed_bar_current(p.game_state.sprint_stamina)
		return

	if Input.is_action_pressed(p.INPUT["sprint"]) and p.game_state.sprint_stamina > 0:
		p.is_sprinting = true
		p.game_state.sprint_stamina -= p.game_state.sprint_stamina_cost * delta
		if p.game_state.sprint_stamina <= 0:
			p.game_state.sprint_stamina = 0
			p.is_sprinting = false
	else:
		p.is_sprinting = false
		if p.game_state.sprint_stamina < p.game_state.sprint_stamina_max:
			p.game_state.sprint_stamina += p.game_state.sprint_stamina_regen * delta
			if p.game_state.sprint_stamina > p.game_state.sprint_stamina_max:
				p.game_state.sprint_stamina = p.game_state.sprint_stamina_max

	p.game_state.speed_bar.update_speed_bar_current(p.game_state.sprint_stamina)

# ============================================================================
#                                 CAMOUFLAGE
# ============================================================================

func process_camouflage():
	if not p.can_camouflage:
		return
	if Input.is_action_just_pressed(p.INPUT["camouflage"]):
		use_camouflage()

func use_camouflage():
	if p.is_camouflaged:
		return
	if not p.game_state.camouflage_unlocked:
		return
	if p.game_state.camouflage_count <= 0:
		return

	# Consomme 1 charge
	p.game_state.camouflage_count -= 1
	if p.game_state.camouflage_count < 0:
		p.game_state.camouflage_count = 0

	# Etat global
	p.game_state.can_camouflage = p.game_state.camouflage_unlocked and p.game_state.camouflage_count > 0
	p.can_camouflage = p.game_state.can_camouflage

	# HUD : update compteur
	if p.game_state.hud:
		p.game_state.hud.update_camouflage_display()

		# Déswitch auto si plus de charges
		if p.game_state.camouflage_count == 0:
			p.game_state.hud.switch_back_to_spear()

	p.hud_mod.refresh_hud_buttons()

	start_camouflage()

func start_camouflage():
	p.is_camouflaged = true
	p.game_state.is_camouflaged = true

	# supprime le noeud de visé des ennemies
	p.turn_axis_parent = p.turn_axis.get_parent()
	p.turn_axis_index = p.turn_axis.get_index()
	p.turn_axis_parent.remove_child(p.turn_axis)

	# HUD : cercle = durée du camouflage
	if p.game_state.hud and p.game_state.has_method("start_camouflage_cooldown"):
		p.game_state.hud.start_camouflage_cooldown(p.camouflage_duration)

	p.hud_mod.refresh_hud_buttons()

	# Effet visuel
	p.sprite.modulate = Color(1, 1, 1, 0.35)

	await p.get_tree().create_timer(p.camouflage_duration).timeout
	stop_camouflage()

func stop_camouflage():
	p.is_camouflaged = false
	p.game_state.is_camouflaged = false

	p.turn_axis_parent.add_child(p.turn_axis)
	p.turn_axis_parent.move_child(p.turn_axis, p.turn_axis_index)

	# Retour visuel
	p.sprite.modulate = Color(1, 1, 1, 1)

	p.hud_mod.refresh_hud_buttons()
