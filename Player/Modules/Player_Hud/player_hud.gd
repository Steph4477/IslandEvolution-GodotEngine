extends Node

var p = null
var gs = null
var hud_parent = null

func setup(player):
	p = player
	gs = p.game_state

func setup_hud():
	if not gs:
		return
	if not gs.hud:
		return

	if gs.hud.has_method("update_lives_display"):
		gs.hud.update_lives_display(gs.lives)

	update_all_displays()
	refresh_buttons()

func update_banane_display():
	if gs and gs.hud and gs.hud.has_method("update_banane_display"):
		gs.hud.update_banane_display()

func update_honey_display():
	if gs and gs.hud and gs.hud.has_method("update_honey_display"):
		gs.hud.update_honey_display()

func update_coco_display():
	if gs and gs.hud and gs.hud.has_method("update_coco_display"):
		gs.hud.update_coco_display()

func update_bone_display():
	if gs and gs.hud and gs.hud.has_method("update_bone_display"):
		gs.hud.update_bone_display()

func update_lance_display():
	if gs and gs.hud and gs.hud.has_method("update_lance_display"):
		gs.hud.update_lance_display()

func update_seed_display():
	if gs and gs.hud and gs.hud.has_method("update_seed_display"):
		gs.hud.update_seed_display(gs.collected_seeds, gs.total_seeds_in_level)

func update_all_displays():
	update_banane_display()
	update_honey_display()
	update_coco_display()
	update_bone_display()
	update_lance_display()
	update_seed_display()

func _resolve_hud_parent():
	if not gs:
		return null
	if not gs.health_bar:
		return null

	var hp = gs.health_bar
	var parent = hp.get_parent()
	return parent

func refresh_buttons():
	if not gs:
		return

	hud_parent = _resolve_hud_parent()
	if not hud_parent:
		return

	var pv = p.pv
	if pv == null:
		pv = 0

	var max_pv = p.max_pv
	if max_pv == null:
		max_pv = 2000

	# Coco / Bone
	if hud_parent.has_node("Gamepad/Coco"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Coco"), p.can_fire_coco)

	if hud_parent.has_node("Gamepad/Bone"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Bone"), p.can_fire_bone)

	# Heal
	var can_heal_banana_btn = pv < max_pv and p.heal_potions.size() > 0 and not p.in_cooldown
	if hud_parent.has_node("Gamepad/Health"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Health"), can_heal_banana_btn)

	var can_heal_honey_btn = pv < max_pv and p.honey_potions.size() > 0 and not p.in_cooldown
	if hud_parent.has_node("Gamepad/Honey"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Honey"), can_heal_honey_btn)

	# Spear -> Camouflage (switch)
	if hud_parent.has_node("Gamepad/Spear"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Spear"), p.can_fire_lance and not p.can_camouflage)

	# Skills
	if hud_parent.has_node("Gamepad/Camouflage"):
		var can_btn = p.can_camouflage
		if gs.is_camouflaged:
			can_btn = false
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Camouflage"), can_btn)

	if hud_parent.has_node("Gamepad/Ramp"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Ramp"), p.can_ramp)

	if hud_parent.has_node("Gamepad/Sprint"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Sprint"), p.can_sprint)
