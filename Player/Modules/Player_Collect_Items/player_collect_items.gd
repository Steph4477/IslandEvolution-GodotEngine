extends Node

var p

func setup(player):
	p = player

# ============================================================================
#                                     COLLECTES
# ============================================================================

func collect_banane(amount = 1):
	for i in range(amount):
		p.heal_potions.append(p.game_state.heal_amount)

	p.banane_count = p.heal_potions.size()

	if p.game_state:
		p.game_state.banane_count = p.banane_count

	p.update_can_heal()

	var hud = p.game_state.hud
	if hud and hud.has_method("anim_to_health_mode"):
		hud.anim_to_health_mode()
	elif hud and hud.has_method("update_banane_display"):
		hud.update_banane_display()

	if hud and hud.has_method("set_button_enabled"):
		hud.set_button_enabled(hud.get_node("Gamepad/Health"), p.can_heal)

	p.hud_mod.update_banane_display()

	if amount == 1:
		p.show_info_popup("1 jus de banane récupéré !")
	else:
		p.show_info_popup(str(amount) + " jus de bananes récupérés !")

	p.hud_mod.refresh_hud_buttons()


func collect_honey(amount = 1):
	for i in range(amount):
		p.honey_potions.append(p.game_state.heal_amount)

	p.honey_count = p.honey_potions.size()

	if p.game_state:
		p.game_state.honey_count = p.honey_count

	var hud = p.game_state.hud
	if hud and hud.has_method("update_honey_display"):
		hud.update_honey_display()
	if hud and hud.has_method("anim_to_honey_mode"):
		hud.anim_to_honey_mode()

	p.hud_mod.refresh_hud_buttons()


func collect_coco(amount = 1, enable_shooting = false):
	p.coco_count += amount

	if enable_shooting:
		p.can_fire_coco = true

	if p.game_state:
		p.game_state.can_fire_coco = p.can_fire_coco
		p.game_state.coco_count = p.coco_count

	var hud = p.game_state.hud
	if hud:
		if hud.has_method("anim_to_coco_mode"):
			hud.anim_to_coco_mode()
		elif hud.has_method("update_coco_display"):
			hud.update_coco_display()

	p.hud_mod.update_coco_display()

	if amount == 1:
		p.show_info_popup("1 noix de coco récupérée !")
	else:
		p.show_info_popup(str(amount) + " noix de coco récupérées !")

	p.hud_mod.refresh_hud_buttons()


func collect_bone(amount = 1, enable_shooting = false):
	p.bone_count += amount

	if enable_shooting:
		p.can_fire_bone = true
		var hud = p.game_state.hud
		if hud and hud.has_method("set_button_enabled"):
			hud.set_button_enabled(hud.get_node("Gamepad/Bone"), true)

	if p.game_state:
		p.game_state.can_fire_bone = p.can_fire_bone
		p.game_state.bone_count = p.bone_count

	var hud2 = p.game_state.hud
	if hud2 and hud2.has_method("anim_to_bone_mode"):
		hud2.anim_to_bone_mode()

	p.hud_mod.update_bone_display()

	if amount == 1:
		p.show_info_popup("1 os récupéré !")
	else:
		p.show_info_popup(str(amount) + " os récupérés !")

	p.hud_mod.refresh_hud_buttons()


func collect_lance(amount = 1, enable_shooting = false):
	p.lance_count += amount

	if enable_shooting:
		p.can_fire_lance = true

	if p.game_state:
		p.game_state.lance_count = p.lance_count
		p.game_state.can_fire_lance = p.can_fire_lance

	var hud = p.game_state.hud
	if hud and hud.has_method("anim_to_spear_mode"):
		hud.anim_to_spear_mode()

	if amount == 1:
		p.show_info_popup("1 lance récupérée !")
	else:
		p.show_info_popup(str(amount) + " lances récupérées !")

	p.hud_mod.refresh_hud_buttons()


func collect_seed(amount = 1):
	var gs = p.game_state

	for i in range(amount):
		gs.add_seed_collected()

	if p.hud_mod.has_method("update_seed_display"):
		p.hud_mod.update_seed_display(gs.collected_seeds, gs.total_seeds_in_level)

	var parent = p.get_parent()
	if parent and parent.has_method("focus_camera_on_totem_with_anim"):
		await parent.focus_camera_on_totem_with_anim(gs.collected_seeds)
