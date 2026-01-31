extends Node

var p = null
var dbg = true

var heal_list = ["health", "honey"]
var heal_index = 0


func setup(player):
	p = player

	# init propre
	p.selected_heal = "health"
	heal_index = 0


func process_input():
	# --- ouvrir / fermer ---
	if Input.is_action_just_pressed(p.INPUT["heal_mode"]):
		p.heal_mode = not p.heal_mode

		var hud = p.game_state.hud

		if p.heal_mode:
			# FORCE HEALTH à l'ouverture (ce que tu veux)
			p.selected_heal = "health"
			heal_index = 0

			if hud and hud.has_method("show_h_selector"):
				hud.show_h_selector()
			if hud and hud.has_method("update_h_selector_position"):
				hud.update_h_selector_position()

		else:
			if hud and hud.has_method("hide_h_selector"):
				hud.hide_h_selector()

	# --- switch ---
	if p.heal_mode and Input.is_action_just_pressed(p.INPUT["heal_switch"]):
		_switch_heal()

	# --- use ---
	if p.heal_mode and Input.is_action_just_pressed(p.INPUT["heal_use"]):
		_use_heal()


func _switch_heal():
	heal_index += 1
	if heal_index >= heal_list.size():
		heal_index = 0

	p.selected_heal = heal_list[heal_index]

	var hud = p.game_state.hud
	if hud and hud.has_method("update_h_selector_position"):
		hud.update_h_selector_position()


func _use_heal():
	if p.selected_heal == "health":
		p.heal_mod.use_health()
	elif p.selected_heal == "honey":
		p.heal_mod.use_honey()
