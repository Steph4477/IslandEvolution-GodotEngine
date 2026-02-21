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

	var first = not p.game_state.camouflage_unlocked

	if first:
		p.game_state.camouflage_unlocked = true

	p.game_state.camouflage_count += amount

	p.can_camouflage = p.game_state.camouflage_unlocked and p.game_state.camouflage_count > 0
	p.game_state.can_camouflage = p.can_camouflage

	var hud = p.game_state.hud
	if hud:
		if first:
			hud.unlock_camouflage_hud()
		hud.update_camouflage_display()

	p.hud_mod.refresh_hud_buttons()


func collect_double_jump():
	p.game_state.double_jump_unlocked = true
	p.popups_mod.show_info_popup("🦘 Double saut débloqué !")


func collect_oxygen(amount):
	p.breath_left += amount
	if p.breath_left > p.max_breath:
		p.breath_left = p.max_breath

	if p.breath_left > 0:
		p.drown_timer.stop()

	if p.breath_mod:
		p.breath_mod.update_bubble_rate()

	if p.game_state and p.game_state.hud:
		p.game_state.hud.update_breath(p.breath_left, p.max_breath)

	if p.breath_left > 0 and p.breath_left <= p.panic_start:
		if p.bubble_timer.is_stopped():
			p.bubble_timer.start()
	else:
		p.bubble_timer.stop()


func collect_ramp():
	var first = not p.game_state.ramp_unlocked
	p.game_state.ramp_unlocked = true
	p.can_ramp = true

	p.popups_mod.show_info("🤸 Tu peux maintenant ramper avec ctrl !")

	var hud = p.game_state.hud
	if hud and first:
		hud.appear_ramp()

	p.hud_mod.refresh_hud_buttons()


func collect_sprint():
	var first = not p.game_state.sprint_unlocked
	p.game_state.sprint_unlocked = true
	p.game_state.sprint_stamina = p.game_state.sprint_stamina_max
	p.can_sprint = true

	if p.game_state.speed_bar:
		p.game_state.speed_bar.visible = true
		p.game_state.speed_bar.update_speed_bar_current(p.game_state.sprint_stamina)

	var hud = p.game_state.hud
	if hud and first:
		hud.appear_sprint()

	p.popups_mod.show_info("⚡ Tu peux maintenant sprinter avec Shift !")
	p.hud_mod.refresh_hud_buttons()
