extends Node

var p

func setup(player):
	p = player

func process():
	process_heal()

func process_heal():
	if Input.is_action_just_pressed(p.INPUT["heal"]):
		use_heal_item()

func use_heal_item():
	if p.game_state.hud.get_node("Gamepad/Honey").visible:
		await use_honey()
		return

	await use_banane()

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
		p.popups_mod.show_info(msg)
		await p.play_anim("empty")
		return

	await p.play_anim("heal")

	p.heal(p.game_state.heal_amount)

	p.heal_potions.pop_front()
	p.banane_count = p.heal_potions.size()

	p.game_state.banane_count = p.banane_count
	p.hud_mod.update_banane_display()

	p.in_cooldown = true
	p.update_can_heal()
	p.hud_mod.refresh_hud_buttons()

	p.game_state.hud.start_banane_cooldown(p.cooldown_potion)

	await p.get_tree().create_timer(p.cooldown_potion).timeout

	p.in_cooldown = false
	p.hud_mod.refresh_hud_buttons()

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
		p.popups_mod.show_info(msg)
		await p.play_anim("empty")
		return

	await p.play_anim("heal")

	p.heal(p.game_state.heal_amount)

	p.honey_potions.pop_front()
	p.honey_count = p.honey_potions.size()

	p.game_state.honey_count = p.honey_count
	p.game_state.hud.update_honey_display()

	p.in_cooldown = true
	p.update_can_heal()
	p.hud_mod.refresh_hud_buttons()

	p.game_state.hud.start_honey_cooldown(p.cooldown_potion)

	await p.get_tree().create_timer(p.cooldown_potion).timeout

	p.in_cooldown = false
	p.hud_mod.refresh_hud_buttons()
