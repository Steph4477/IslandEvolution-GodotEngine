extends Node

var p = null
var dbg = true

var heal_list = []
var heal_index = 0

func setup(player):
	p = player
	_rebuild_heal_list()
	_fix_heal_selection()
	_update_heal_hud()

	if dbg:
		print("[SWITCH_HEAL][READY] heal_mode=", p.heal_mode, " selected=", p.selected_heal, " list=", heal_list)

func update_input():
	if Input.is_action_just_pressed(p.INPUT["heal_mode"]):
		_toggle_heal_mode()
		return

	if not p.heal_mode:
		return

	if Input.is_action_just_pressed(p.INPUT["heal_switch"]):
		_cycle_heal()
		_update_heal_hud()
		return

	if Input.is_action_just_pressed(p.INPUT["heal_use"]):
		_use_selected_heal()
		return

func _toggle_heal_mode():
	if p.throw_mode:
		p.throw_mode = false
		_update_throw_hud_off()

	if p.skill_mode:
		p.skill_mode = false
		_update_skill_hud_off()

	_rebuild_heal_list()

	# rien dispo => ferme
	if heal_list.size() == 0:
		p.heal_mode = false
		_update_heal_hud()
		return

	p.heal_mode = not p.heal_mode
	_fix_heal_selection()
	_update_heal_hud()

	if dbg:
		print("[SWITCH_HEAL] toggle =>", p.heal_mode, " selected=", p.selected_heal, " list=", heal_list)

func _rebuild_heal_list():
	heal_list.clear()
	var gs = p.game_state

	if gs.banane_count > 0:
		heal_list.append("banane")
	if gs.honey_count > 0:
		heal_list.append("honey")

func _fix_heal_selection():
	if heal_list.size() == 0:
		return

	heal_index = heal_list.find(p.selected_heal)
	if heal_index == -1:
		heal_index = 0
		p.selected_heal = heal_list[0]

func _cycle_heal():
	_rebuild_heal_list()

	if heal_list.size() == 0:
		p.heal_mode = false
		return

	if heal_list.size() == 1:
		_fix_heal_selection()
		return

	heal_index = heal_list.find(p.selected_heal)
	if heal_index == -1:
		heal_index = 0
	else:
		heal_index += 1
		if heal_index >= heal_list.size():
			heal_index = 0

	p.selected_heal = heal_list[heal_index]

	if dbg:
		print("[SWITCH_HEAL] switch => selected=", p.selected_heal, " idx=", heal_index, " list=", heal_list)

func _use_selected_heal():
	_rebuild_heal_list()
	if heal_list.size() == 0:
		p.heal_mode = false
		_update_heal_hud()
		return

	_fix_heal_selection()
	_update_heal_hud()

	p.heal_mod.use_heal_item()

func _get_hud():
	return p.game_state.hud

func _update_heal_hud():
	var hud = _get_hud()
	if p.heal_mode:
		hud.show_heal_mode(p.selected_heal)
		hud.set_heal_selected(p.selected_heal)
	else:
		hud.hide_heal_mode()

func _update_throw_hud_off():
	var hud = _get_hud()
	hud.hide_throw_mode()

func _update_skill_hud_off():
	var hud = _get_hud()
	hud.set_skill_mode(false)
