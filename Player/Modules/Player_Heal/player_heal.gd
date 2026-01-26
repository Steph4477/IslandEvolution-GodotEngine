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
		# Si le bouton Honey est visible, on est en mode miel
		if p.game_state.hud.has_node("Gamepad/Honey"):
			var honey_btn = p.game_state.hud.get_node("Gamepad/Honey")
			if honey_btn.visible:
				use_honey()
				return

	# Sinon on utilise le jus de banane
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
		p.show_info_popup(msg)
		await p.play_anim("empty")
		return

	await p.play_anim("heal")

	p.heal(p.game_state.heal_amount)

	if not p.heal_potions.is_empty():
		p.heal_potions.pop_front()

	p.banane_count = p.heal_potions.size()

	if p.game_state:
		p.game_state.banane_count = p.banane_count

	p.update_banane_display()

	p.in_cooldown = true
	p.update_can_heal()
	p.hud_mod.refresh_hud_buttons()
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
		p.show_info_popup(msg)
		await p.play_anim("empty")
		return

	await p.play_anim("heal")

	p.heal(p.game_state.heal_amount)

	if not p.honey_potions.is_empty():
		p.honey_potions.pop_front()

	p.honey_count = p.honey_potions.size()

	if p.game_state:
		p.game_state.honey_count = p.honey_count

	if p.game_state and p.game_state.hud and p.game_state.hud.has_method("update_honey_display"):
		p.game_state.hud.update_honey_display()

	p.in_cooldown = true
	p.update_can_heal()
	p.hud_mod.refresh_hud_buttons()
	start_potion_cooldown("honey")

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
	p.refresh_hud_buttons()
