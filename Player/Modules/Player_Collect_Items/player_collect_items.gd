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

	p.update_banane_display()
	p.show_info_popup("5 jus de bananes récupérés !")
	p.refresh_hud_buttons()


func collect_honey(amount = 1):
	for i in range(amount):
		p.honey_potions.append(p.game_state.heal_amount)

	p.honey_count = p.honey_potions.size()
	p.game_state.honey_count = p.honey_count

	p.game_state.hud.update_honey_display()
	p.game_state.hud.anim_to_honey_mode()

	p.refresh_hud_buttons()

func collect_coco(amount = 1, enable_shooting = false):
	p.coco_count += amount

	if enable_shooting:
		p.can_fire_coco = true

	if p.game_state:
		p.game_state.can_fire_coco = p.can_fire_coco
		p.game_state.coco_count = p.coco_count

	if p.game_state.hud:
		if p.game_state.hud.has_method("anim_to_coco_mode"):
			p.game_state.hud.anim_to_coco_mode()
		elif p.game_state.hud.has_method("update_coco_display"):
			p.game_state.hud.update_coco_display()

	p.update_coco_display()
	p.show_info_popup("Tu peux lancer 3 noix de coco")
	p.refresh_hud_buttons()

func collect_bone(amount = 1, enable_shooting = false):
	p.bone_count += amount

	if enable_shooting:
		p.can_fire_bone = true
		var hud = p.game_state.hud
		if hud.has_method("set_button_enabled"):
			hud.set_button_enabled(hud.get_node("Gamepad/Bone"), true)

	if p.game_state:
		p.game_state.can_fire_bone = p.can_fire_bone
		p.game_state.bone_count = p.bone_count

		if p.game_state.hud and p.game_state.hud.has_method("anim_to_bone_mode"):
			p.game_state.hud.anim_to_bone_mode()

	p.update_bone_display()
	p.show_info_popup("Tu peux lancer 3 os")
	p.refresh_hud_buttons()


func collect_lance(amount = 1, enable_shooting = false):
	p.lance_count += amount

	if enable_shooting:
		p.can_fire_lance = true

	p.game_state.lance_count = p.lance_count
	p.game_state.can_fire_lance = p.can_fire_lance

	p.game_state.hud.anim_to_spear_mode()

	p.show_info_popup("Tu peux shooter des lances")
	p.refresh_hud_buttons()


func collect_seed(amount = 1):
	var gs = get_node("/root/GameState")

	for i in range(amount):
		gs.add_seed_collected()

	if gs.hud and gs.hud.has_method("update_seed_display"):
		gs.hud.update_seed_display(gs.collected_seeds, gs.total_seeds_in_level)

	var parent = p.get_parent()
	if parent and parent.has_method("focus_camera_on_totem_with_anim"):
		await parent.focus_camera_on_totem_with_anim(gs.collected_seeds)
