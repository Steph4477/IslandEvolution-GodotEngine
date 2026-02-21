extends Node

var p = null
var dbg = true

var skill_list = []
var skill_index = 0

func setup(player):
	p = player
	_rebuild_skill_list()
	_fix_skill_selection()
	_update_skill_hud()

	if dbg:
		print("[SWITCH_SKILL][READY] skill_mode=", p.skill_mode, " selected=", p.selected_skill, " list=", skill_list)

func update_input():
	if Input.is_action_just_pressed(p.INPUT["skill_mode"]):
		_toggle_skill_mode()
		return

	if not p.skill_mode:
		return

	if Input.is_action_just_pressed(p.INPUT["skill_switch"]):
		_cycle_skill()
		_update_skill_hud()
		return

	if Input.is_action_just_pressed(p.INPUT["throw_fire"]):
		_use_selected_skill()
		return

func _toggle_skill_mode():
	if p.throw_mode:
		p.throw_mode = false
		_update_throw_hud_off()

	if p.heal_mode:
		p.heal_mode = false
		_update_heal_hud_off()

	_rebuild_skill_list()

	# rien dispo => ferme
	if skill_list.size() == 0:
		p.skill_mode = false
		_update_skill_hud()
		return

	p.skill_mode = not p.skill_mode
	_fix_skill_selection()
	_update_skill_hud()

	if dbg:
		print("[SWITCH_SKILL] toggle =>", p.skill_mode, " selected=", p.selected_skill, " list=", skill_list)

func _rebuild_skill_list():
	skill_list.clear()
	var gs = p.game_state

	if gs.ramp_unlocked:
		skill_list.append("ramp")
	if gs.sprint_unlocked:
		skill_list.append("sprint")
	if gs.camouflage_unlocked and gs.camouflage_count > 0:
		skill_list.append("camouflage")

func _fix_skill_selection():
	if skill_list.size() == 0:
		return

	skill_index = skill_list.find(p.selected_skill)
	if skill_index == -1:
		skill_index = 0
		p.selected_skill = skill_list[0]

func _cycle_skill():
	_rebuild_skill_list()

	if skill_list.size() == 0:
		p.skill_mode = false
		return

	if skill_list.size() == 1:
		_fix_skill_selection()
		return

	skill_index = skill_list.find(p.selected_skill)
	if skill_index == -1:
		skill_index = 0
	else:
		skill_index += 1
		if skill_index >= skill_list.size():
			skill_index = 0

	p.selected_skill = skill_list[skill_index]

	if dbg:
		print("[SWITCH_SKILL] switch => selected=", p.selected_skill, " idx=", skill_index, " list=", skill_list)

func _use_selected_skill():
	_rebuild_skill_list()
	if skill_list.size() == 0:
		p.skill_mode = false
		_update_skill_hud()
		return

	_fix_skill_selection()

	if p.selected_skill == "ramp":
		p.skills_mod.toggle_ramp()
		return

	if p.selected_skill == "sprint":
		p.skills_mod.use_sprint()
		return

	p.skills_mod.use_camouflage()

func _get_hud():
	return p.game_state.hud

func _update_skill_hud():
	var hud = _get_hud()
	if p.skill_mode:
		hud.set_skill_mode(true)
		hud.set_skill_selected(p.selected_skill)
	else:
		hud.set_skill_mode(false)

func _update_throw_hud_off():
	var hud = _get_hud()
	hud.hide_throw_mode()

func _update_heal_hud_off():
	var hud = _get_hud()
	hud.hide_heal_mode()
