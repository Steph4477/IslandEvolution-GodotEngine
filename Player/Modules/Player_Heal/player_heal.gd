extends Node

var p

func setup(player):
	p = player

# ============================================================================
#                                 PROCESS
# ============================================================================
func process():
	process_heal()

# ============================================================================
#                                 HEAL
# ============================================================================
func process_heal():
	if Input.is_action_just_pressed(p.INPUT["heal"]):
		use_heal_item()

# --- Choix entre le jus de banane et le miel ---
func use_heal_item():
	if p.game_state and p.game_state.hud:
		if p.game_state.hud.has_node("Gamepad/Honey"):
			var honey_btn = p.game_state.hud.get_node("Gamepad/Honey")
			if honey_btn.visible:
				use_honey()
				return

	use_banane()

func use_banane():
	if not p.is_on_floor():
		return

	var msg = ""
	if p.pv >= p.max_pv:
		msg = "PV au max !"
	elif p.in_cooldown:
		msg = "⏳ Potion en recharge..."
	elif p.heal_potions.is_empty():
		msg = "Aucune potion !"

	if msg != "":
		p.popups_mod.info(msg)
		await p.anim_mod.play_locked("empty")
		return

	await p.anim_mod.play_locked("heal")

	apply_heal(p.game_state.heal_amount)

	if not p.heal_potions.is_empty():
		p.heal_potions.pop_front()

	p.banane_count = p.heal_potions.size()

	if p.game_state:
		p.game_state.banane_count = p.banane_count

	p.hud_mod.update_banane_display()

	p.in_cooldown = true
	refresh_can_heal()
	p.hud_mod.refresh_buttons()
	start_potion_cooldown("banane")

func use_honey():
	if not p.is_on_floor():
		return

	var msg = ""
	if p.pv >= p.max_pv:
		msg = "PV au max !"
	elif p.in_cooldown:
		msg = "⏳ Potion en recharge..."
	elif p.honey_potions.is_empty():
		msg = "Aucun miel !"

	if msg != "":
		p.popups_mod.info(msg)
		await p.anim_mod.play_locked("empty")
		return

	await p.anim_mod.play_locked("heal")

	apply_heal(p.game_state.heal_amount)

	if not p.honey_potions.is_empty():
		p.honey_potions.pop_front()

	p.honey_count = p.honey_potions.size()

	if p.game_state:
		p.game_state.honey_count = p.honey_count

	p.hud_mod.update_honey_display()

	p.in_cooldown = true
	refresh_can_heal()
	p.hud_mod.refresh_buttons()
	start_potion_cooldown("honey")

# ============================================================================
#                               API HEAL (remplace wrappers)
# ============================================================================
func apply_heal(amount):
	p.pv = clamp(p.pv + amount, 0, p.max_pv)

	if p.game_state:
		p.game_state.health_bar.set_value(p.pv)

func refresh_can_heal():
	p.can_heal = p.heal_potions.size() > 0 and p.pv < p.max_pv and not p.in_cooldown

func start_potion_cooldown(item):
	p.in_cooldown = true

	var hud = null
	if p.game_state and p.game_state.health_bar:
		hud = p.game_state.health_bar.get_parent()

	if hud:
		if item == "banane":
			if hud.has_method("start_banane_cooldown"):
				hud.start_banane_cooldown(p.cooldown_potion)
		elif item == "honey":
			if hud.has_method("start_honey_cooldown"):
				hud.start_honey_cooldown(p.cooldown_potion)

	await p.get_tree().create_timer(p.cooldown_potion).timeout
	p.in_cooldown = false
	refresh_can_heal()
	p.hud_mod.refresh_buttons()
