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
	p.game_state.banane_count = p.banane_count

	p.update_can_heal()

	var hud = p.game_state.hud
	hud.anim_to_health_mode()
	hud.update_banane_display()
	hud.set_button_enabled(hud.get_node("Gamepad/Health"), p.can_heal)

	if amount == 1:
		p.popups_mod.show_info("1 jus de banane récupéré !")
	else:
		p.popups_mod.show_info(str(amount) + " jus de bananes récupérés !")

	# si tu as une logique centralisée dans player_hud.gd, garde juste refresh
	p.hud_mod.refresh_hud_buttons()


func collect_honey(amount = 1):
	for i in range(amount):
		p.honey_potions.append(p.game_state.heal_amount)

	p.honey_count = p.honey_potions.size()
	p.game_state.honey_count = p.honey_count

	var hud = p.game_state.hud
	hud.anim_to_honey_mode()
	hud.update_honey_display()
	hud.set_button_enabled(hud.get_node("Gamepad/Honey"), p.honey_count > 0)

	if amount == 1:
		p.popups_mod.show_info("1 miel récupéré !")
	else:
		p.popups_mod.show_info(str(amount) + " miels récupérés !")

	p.hud_mod.refresh_hud_buttons()


func collect_coco(amount = 1, enable_shooting = false):
	var first = p.game_state.coco_count == 0

	p.coco_count += amount
	if enable_shooting:
		p.can_fire_coco = true

	p.game_state.coco_count = p.coco_count
	p.game_state.can_fire_coco = p.can_fire_coco

	var hud = p.game_state.hud

	if first:
		hud.appear_coco()
	else:
		hud.update_coco_display()

	p.hud_mod.refresh_hud_buttons()


func collect_bone(amount = 1, enable_shooting = false):
	var first_loot = p.game_state.bone_count == 0

	p.bone_count += amount

	if enable_shooting:
		p.can_fire_bone = true

	p.game_state.bone_count = p.bone_count
	p.game_state.can_fire_bone = p.can_fire_bone

	var hud = p.game_state.hud

	if first_loot:
		hud.appear_bone()
	else:
		hud.update_bone_display()

	p.hud_mod.refresh_hud_buttons()

	if amount == 1:
		p.popups_mod.show_info("1 os récupéré !")
	else:
		p.popups_mod.show_info(str(amount) + " os récupérés !")


func collect_lance(amount = 1):
	var first = p.game_state.lance_count == 0

	p.lance_count += amount

	# loot lance = tir autorisé
	p.can_fire_lance = true
	p.game_state.can_fire_lance = true

	p.game_state.lance_count = p.lance_count

	var hud = p.game_state.hud

	if first:
		hud.appear_spear()
	else:
		hud.update_lance_display()

	p.hud_mod.refresh_hud_buttons()


func collect_seed(amount = 1):
	var gs = p.game_state

	for i in range(amount):
		gs.add_seed_collected()

	p.hud_mod.update_seed_display(gs.collected_seeds, gs.total_seeds_in_level)

	var parent = p.get_parent()
	if parent and parent.has_method("focus_camera_on_totem_with_anim"):
		await parent.focus_camera_on_totem_with_anim(gs.collected_seeds)

# --- Craft skill_air
func collect_leaf():
	if p.game_state.leaf_collected:
		return

	p.game_state.leaf_collected = true

	p.popups_mod.show_info("Feuille volante récupéré")

func collect_idole():
	if p.game_state.idole_collected:
		return

	p.game_state.idole_collected = true

	p.popups_mod.show_info("Idole du vent récupéré")

# --- Craft skill_fire
func collect_wood():
	if p.game_state.wood_collected:
		return

	p.game_state.wood_collected = true

	p.popups_mod.show_info("Bois récupéré")

func collect_stone():
	if p.game_state.stone_collected:
		return

	p.game_state.stone_collected = true

	p.popups_mod.show_info("Cette pierre pourrait servir…")
