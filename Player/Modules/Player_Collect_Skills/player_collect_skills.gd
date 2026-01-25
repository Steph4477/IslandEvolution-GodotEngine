extends Node

var p

func setup(player):
	p = player

# ============================================================================
#                                     COLLECTES 
# ============================================================================
func collect_camouflage(amount = 1):
	if not p.game_state:
		return

	if not p.game_state.camouflage_unlocked:
		p.game_state.camouflage_unlocked = true

	p.game_state.camouflage_count += amount

	p.can_camouflage = p.game_state.camouflage_unlocked and p.game_state.camouflage_count > 0
	p.game_state.can_camouflage = p.can_camouflage

	if p.game_state.hud:
		if p.game_state.hud.has_method("unlock_camouflage_hud"):
			p.game_state.hud.unlock_camouflage_hud()
		if p.game_state.hud.has_method("update_camouflage_display"):
			p.game_state.hud.update_camouflage_display()

	p.refresh_hud_buttons()

func collect_double_jump():
	p.game_state.double_jump_unlocked = true
	p.show_info_popup("🦘 Double saut débloqué !")


func collect_oxygen(amount):
	p.breath_left += amount
	if p.breath_left > p.max_breath:
		p.breath_left = p.max_breath

	if p.breath_left > 0:
		p.drown_timer.stop()

	p.update_bubble_rate()
	p.game_state.hud.update_breath(p.breath_left, p.max_breath)

	if p.breath_left > 0 and p.breath_left <= p.panic_start:
		if p.bubble_timer.is_stopped():
			p.bubble_timer.start()
	else:
		p.bubble_timer.stop()

func collect_ramp():
	# Débloque côté GameState (source de vérité)
	p.game_state.ramp_unlocked = true

	# Sync côté Player (runtime)
	p.can_ramp = true

	p.show_info_popup("🤸 Tu peux maintenant ramper avec ctrl !")

	# HUD
	var hud = p.game_state.hud
	if not hud:
		return

	if hud.has_node("Gamepad/Ramp"):
		var btn = hud.get_node("Gamepad/Ramp")
		btn.visible = true
		hud.set_button_enabled(btn, true)

	# Animation : utilise has_method/has_node, pas hud.anim en dur
	if hud.has_node("AnimationPlayer"):
		var a = hud.get_node("AnimationPlayer")
		if a.has_animation("appear_ramp"):
			a.play("appear_ramp")
	elif hud.has_method("play_hud_anim"):
		hud.play_hud_anim("appear_ramp")

	p.refresh_hud_buttons()


func collect_sprint():
	# Débloque côté GameState (source de vérité)
	p.game_state.sprint_unlocked = true
	p.game_state.sprint_stamina = p.game_state.sprint_stamina_max

	# Sync côté Player (runtime)
	p.can_sprint = true

	# SpeedBar
	if p.game_state.speed_bar:
		p.game_state.speed_bar.visible = true
		p.game_state.speed_bar.update_speed_bar_current(p.game_state.sprint_stamina)

	# HUD
	var hud = p.game_state.hud
	if hud:
		if hud.has_node("Gamepad/Sprint"):
			var btn = hud.get_node("Gamepad/Sprint")
			btn.visible = true
			hud.set_button_enabled(btn, true)

		# Anim : ne suppose pas hud.anim
		if hud.has_node("AnimationPlayer"):
			var a = hud.get_node("AnimationPlayer")
			if a.has_animation("appear_sprint"):
				a.play("appear_sprint")

	p.show_info_popup("⚡ Tu peux maintenant sprinter avec Shift !")
	p.refresh_hud_buttons()
