extends Node

var p

func setup(player):
	p = player

# ============================================================================
#                       DOMMAGES ET MORT
# ============================================================================
func on_hit(damage):
	if p.is_harpooned:
		return

	if not p.can_be_damaged or p.is_dead:
		return

	p.can_be_damaged = false
	p.is_hit_locked = true
	p.can_move = false
	p.velocity.x = 0

	p.pv -= damage
	p.pv = clamp(p.pv, 0, p.max_pv)

	if p.game_state and p.game_state.hud:
		p.game_state.hud.update_health_bar(p.pv, p.max_pv)

	if p.game_state:
		p.game_state.update_boss_fight_hud()

	if p.popups_mod:
		p.popups_mod.show_damage(damage)

	p.update_can_heal()
	p.hud_mod.refresh_hud_buttons()

	var hud = null
	if p.game_state and p.game_state.health_bar:
		hud = p.game_state.health_bar.get_parent()

	if hud and hud.has_method("set_button_enabled"):
		var can_heal_btn = (p.pv < p.max_pv and p.heal_potions.size() > 0 and not p.in_cooldown)
		if hud.has_node("Gamepad/Health"):
			hud.set_button_enabled(hud.get_node("Gamepad/Health"), can_heal_btn)

		var can_honey_btn = (p.pv < p.max_pv and p.honey_potions.size() > 0 and not p.in_cooldown)
		if hud.has_node("Gamepad/Honey"):
			hud.set_button_enabled(hud.get_node("Gamepad/Honey"), can_honey_btn)

	if p.pv <= 0:
		p.is_hit_locked = false
		p.can_move = true
		await die()
		return

	if p.is_swimming_under_water:
		await p.play_anim("onhit_under_swim")
	elif p.is_swimming:
		await p.play_anim("onhit_swim")
	else:
		await p.play_anim("onhit")

	await p.get_tree().create_timer(p.hit_lock_time).timeout

	p.is_hit_locked = false
	p.can_move = true
	p.can_be_damaged = true

func die():
	if p.is_dead:
		return

	p.is_harpooned = false
	p.harpoon_owner = null
	p.can_move = true

	p.is_dead = true
	p.animation_locked = true
	p.anim.play("die")

	if p.game_state:
		p.game_state.lose_life()

		if p.game_state.hud and p.game_state.hud.has_method("update_lives_display"):
			p.game_state.hud.update_lives_display(p.game_state.lives)

	await p.anim.animation_finished

	p.is_dead = false
	p.modulate = Color(1, 1, 1, 1)
	await p.get_tree().process_frame

	# stop breath propre
	if p.breath_mod:
		p.breath_mod.stop_underwater_breath(true)

func reset_state():
	if p.breath_mod:
		p.breath_mod.stop_underwater_breath(true)

	p.is_dead = false
	p.animation_locked = false
	p.visible = true

	p.pv = p.max_pv

	p.heal_potions.clear()
	p.honey_potions.clear()

	p.banane_count = 0
	p.honey_count = 0
	p.coco_count = 0
	p.bone_count = 0
	p.seed_count = 0
	p.lance_count = 0

	p.can_fire_coco = false
	p.can_fire_lance = false
	p.can_fire_bone = false

	if p.game_state:
		p.game_state.banane_count = 0
		p.game_state.honey_count = 0
		p.game_state.coco_count = 0
		p.game_state.bone_count = 0
		p.game_state.seed_count = 0
		p.game_state.lance_count = 0

		p.game_state.can_fire_coco = false
		p.game_state.can_fire_lance = false
		p.game_state.can_fire_bone = false
		p.can_camouflage = p.game_state.can_camouflage

		if p.game_state.hud and p.game_state.hud.has_method("update_health_bar"):
			p.game_state.hud.update_health_bar(p.pv, p.max_pv)

		if p.game_state.hud and p.game_state.hud.has_method("update_lives_display"):
			p.game_state.hud.update_lives_display(p.game_state.lives)
		if p.game_state.hud and p.game_state.hud.has_method("update_lance_display"):
			p.game_state.hud.update_lance_display()

	await p.get_tree().create_timer(1.0).timeout
	p.can_be_damaged = true
