extends Node

var p = null
var hud_ready = false

func setup(player):
	p = player
	_bind_hud_async()

func _bind_hud_async():
	hud_ready = false

	# Attendre que GameState + HUD soient bien prêts (spawn dynamique / reload / respawn)
	while p and p.game_state and p.game_state.hud == null:
		await get_tree().process_frame

	# Si GameState n'existe pas (cas extrême), on stop
	if p == null:
		return
	if p.game_state == null:
		return
	if p.game_state.hud == null:
		return

	# HUD prêt
	hud_ready = true

	# Init HUD
	setup_hud()

func wait_until_ready():
	while not hud_ready:
		await get_tree().process_frame

func setup_hud():
	if not p:
		return
	if not p.game_state:
		return
	if not p.game_state.hud:
		return

	# Le HUD gère l'affichage via ses méthodes update
	if p.game_state.hud.has_method("update_lives_display"):
		p.game_state.hud.update_lives_display(p.game_state.lives)

	update_all_displays()
	refresh_hud_buttons()


# =============================================================================
#                               HUD
# =============================================================================
func update_banane_display():
	if p.game_state and p.game_state.hud and p.game_state.hud.has_method("update_banane_display"):
		p.game_state.hud.update_banane_display()

func update_honey_display():
	if p.game_state and p.game_state.hud and p.game_state.hud.has_method("update_honey_display"):
		p.game_state.hud.update_honey_display()

func update_coco_display():
	if p.game_state and p.game_state.hud and p.game_state.hud.has_method("update_coco_display"):
		p.game_state.hud.update_coco_display()

func update_bone_display():
	if p.game_state and p.game_state.hud and p.game_state.hud.has_method("update_bone_display"):
		p.game_state.hud.update_bone_display()

func update_lance_display():
	if p.game_state and p.game_state.hud and p.game_state.hud.has_method("update_lance_display"):
		p.game_state.hud.update_lance_display()

func update_seed_display(collected_seeds, total_seeds):
	if not p:
		return
	if not p.game_state:
		return
	if not p.game_state.hud:
		return
	if not p.game_state.hud.has_method("update_seed_display"):
		return

	p.game_state.hud.update_seed_display(collected_seeds, total_seeds)


func update_all_displays():
	update_banane_display()
	update_honey_display()
	update_coco_display()
	update_bone_display()
	update_lance_display()

	if p and p.game_state:
		update_seed_display(p.game_state.collected_seeds, p.game_state.total_seeds_in_level)


func refresh_hud_buttons():
	if not p:
		return
	if not p.game_state:
		return
	if not p.game_state.health_bar:
		return

	var hud_parent = p.game_state.health_bar.get_parent()
	if not hud_parent:
		return

	# Coco / Bone
	if hud_parent.has_node("Gamepad/Coco"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Coco"), p.can_fire_coco)

	if hud_parent.has_node("Gamepad/Bone"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Bone"), p.can_fire_bone)

	# Heal
	var can_heal_banana_btn = p.pv < p.max_pv and p.heal_potions.size() > 0 and not p.in_cooldown
	if hud_parent.has_node("Gamepad/Health"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Health"), can_heal_banana_btn)

	var can_heal_honey_btn = p.pv < p.max_pv and p.honey_potions.size() > 0 and not p.in_cooldown
	if hud_parent.has_node("Gamepad/Honey"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Honey"), can_heal_honey_btn)

	# Spear -> Camouflage (switch)
	if hud_parent.has_node("Gamepad/Spear"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Spear"), p.can_fire_lance and not p.can_camouflage)

	# Skills
	if hud_parent.has_node("Gamepad/Camouflage"):
		var can_btn = p.can_camouflage
		if p.game_state and p.game_state.is_camouflaged:
			can_btn = false
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Camouflage"), can_btn)

	if hud_parent.has_node("Gamepad/Ramp"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Ramp"), p.can_ramp)

	if hud_parent.has_node("Gamepad/Sprint"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Sprint"), p.can_sprint)
