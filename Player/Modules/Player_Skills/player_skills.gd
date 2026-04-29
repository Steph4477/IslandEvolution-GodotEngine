extends Node

var p
var saved_turnaxis_local_pos = Vector2.ZERO
var saved_turnaxis_top_level = false

# sprint button state = module (pas Player)
var sprint_button_active = false

func setup(player):
	p = player

# ============================================================================
#                                 PROCESS
# ============================================================================
func process(delta):
	process_ramp()
	process_sprint(delta)
	process_camouflage()
	process_fire_buff()

# ============================================================================
#                                 RAMP
# ============================================================================
func process_ramp():
	if p.can_ramp and Input.is_action_just_pressed(p.INPUT["ramping"]) and p.is_on_floor() and not p.ramp_locked:
		toggle_ramp()

func toggle_ramp():
	if not p.can_ramp :
		return
	if not p.is_on_floor():
		return
	if p.ramp_locked:
		return

	p.ramp_locked = true
	p.is_ramping = not p.is_ramping

	if p.is_ramping:
		p.popups_mod.show_info("🧎 Rampe activée !")
		p.get_node("ColStand").disabled = true
		p.get_node("ColRamp").disabled = false
	else:
		p.popups_mod.show_info("🚶 Rampe désactivée !")
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
		sprint_button_active = false
		return

	if p.is_swimming or p.is_swimming_under_water or p.is_ramping or p.is_on_liana:
		p.is_sprinting = false
		if p.game_state.sprint_stamina < p.game_state.sprint_stamina_max:
			p.game_state.sprint_stamina += p.game_state.sprint_stamina_regen * delta
			if p.game_state.sprint_stamina > p.game_state.sprint_stamina_max:
				p.game_state.sprint_stamina = p.game_state.sprint_stamina_max
		if p.game_state.speed_bar:
			p.game_state.speed_bar.update_speed_bar_current(p.game_state.sprint_stamina)
		return

	var wants_sprint = Input.is_action_pressed(p.INPUT["sprint"]) or sprint_button_active

	if wants_sprint and p.game_state.sprint_stamina > 0:
		p.is_sprinting = true
		p.game_state.sprint_stamina -= p.game_state.sprint_stamina_cost * delta
		if p.game_state.sprint_stamina <= 0:
			p.game_state.sprint_stamina = 0
			p.is_sprinting = false
			sprint_button_active = false
	else:
		p.is_sprinting = false
		if p.game_state.sprint_stamina < p.game_state.sprint_stamina_max:
			p.game_state.sprint_stamina += p.game_state.sprint_stamina_regen * delta
			if p.game_state.sprint_stamina > p.game_state.sprint_stamina_max:
				p.game_state.sprint_stamina = p.game_state.sprint_stamina_max

	if p.game_state.speed_bar:
		p.game_state.speed_bar.update_speed_bar_current(p.game_state.sprint_stamina)

func use_sprint():
	if not p.game_state:
		return
	if not p.game_state.sprint_unlocked:
		return

	sprint_button_active = not sprint_button_active

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

	p.game_state.camouflage_count -= 1
	if p.game_state.camouflage_count < 0:
		p.game_state.camouflage_count = 0

	p.game_state.can_camouflage = p.game_state.camouflage_unlocked and p.game_state.camouflage_count > 0
	p.can_camouflage = p.game_state.can_camouflage

	if p.game_state.hud:
		p.game_state.hud.update_camouflage_display()

	p.hud_mod.refresh_hud_buttons()
	start_camouflage()

func start_camouflage():
	p.is_camouflaged = true
	p.game_state.is_camouflaged = true

	saved_turnaxis_local_pos = p.turn_axis.position
	saved_turnaxis_top_level = p.turn_axis.top_level

	p.turn_axis.top_level = true
	p.turn_axis.global_position = p.turn_axis.global_position
	p.turn_axis.visible = false

	p.sprite.modulate.a = 0.5

	await p.get_tree().create_timer(p.camouflage_duration).timeout
	stop_camouflage()

func stop_camouflage():
	p.is_camouflaged = false
	p.game_state.is_camouflaged = false

	p.turn_axis.top_level = saved_turnaxis_top_level
	p.turn_axis.position = saved_turnaxis_local_pos
	p.turn_axis.visible = true

	p.sprite.modulate.a = 1.0

	p.hud_mod.refresh_hud_buttons()

# ============================================================================
#                                 BUFF
# ============================================================================
# --- Fire ___
func process_fire_buff():
	if Input.is_action_just_pressed(p.INPUT["fire_buff"]):
		use_fire_buff()

func use_fire_buff():
	if not p.game_state:
		return
	if not p.game_state.fire_buff_unlocked:
		return
	if p.fire_buff_active:
		return
	if p.fire_buff_mod == null:
		return

	p.fire_buff_mod.activate_fire_buff()
	p.popups_mod.show_info("🔥 Buff feu activé !")

# --- Air ---
func process_air_buff():
	if Input.is_action_just_pressed(p.INPUT["air_buff"]):
		use_fire_buff()

func use_air_buff():
	if not p.game_state:
		return
	if not p.game_state.air_buff_unlocked:
		return
	if p.air_buff_active:
		return
	if p.air_buff_mod == null:
		return

	p.air_buff_mod.activate_air_buff()
	p.popups_mod.show_info("🌀 Buff air activé !")
