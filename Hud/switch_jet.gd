extends Node

var p = null
var dbg = true

var throw_list = []
var throw_index = 0

func setup(player):
	p = player
	_rebuild_throw_list()
	_fix_throw_selection()
	_update_throw_hud()

	if dbg:
		print("[SWITCH_JET][READY] throw_mode=", p.throw_mode, " selected=", p.selected_throw_weapon, " list=", throw_list)

func update_input():
	if Input.is_action_just_pressed(p.INPUT["throw_mode"]):
		_enable_throw_mode()
		return

	if not p.throw_mode:
		return

	if Input.is_action_just_pressed(p.INPUT["throw_switch"]):
		_cycle_throw()
		_update_throw_hud()
		return

	if Input.is_action_just_pressed(p.INPUT["throw_fire"]):
		_fire_throw_direct()
		return

func _enable_throw_mode():
	if p.skill_mode:
		p.skill_mode = false
		_update_skill_hud_off()

	if p.heal_mode:
		p.heal_mode = false
		_update_heal_hud_off()

	_rebuild_throw_list()

	if throw_list.size() == 0:
		p.throw_mode = false
		_update_throw_hud()
		return

	if p.throw_mode:
		_fix_throw_selection()
		_update_throw_hud()
		return

	p.throw_mode = true
	_fix_throw_selection()
	_update_throw_hud()

	if dbg:
		print("[SWITCH_JET] enable => throw_mode=true selected=", p.selected_throw_weapon, " list=", throw_list)

func _rebuild_throw_list():
	throw_list.clear()
	var gs = p.game_state

	if gs.coco_count > 0 or gs.can_fire_coco:
		throw_list.append("coco")
	if gs.bone_count > 0 or gs.can_fire_bone:
		throw_list.append("bone")
	if gs.lance_count > 0 or gs.can_fire_lance:
		throw_list.append("lance")

func _fix_throw_selection():
	if throw_list.size() == 0:
		return

	throw_index = throw_list.find(p.selected_throw_weapon)
	if throw_index == -1:
		throw_index = 0
		p.selected_throw_weapon = throw_list[0]

func _cycle_throw():
	_rebuild_throw_list()

	if throw_list.size() == 0:
		p.throw_mode = false
		return

	if throw_list.size() == 1:
		_fix_throw_selection()
		return

	throw_index = throw_list.find(p.selected_throw_weapon)
	if throw_index == -1:
		throw_index = 0
	else:
		throw_index += 1
		if throw_index >= throw_list.size():
			throw_index = 0

	p.selected_throw_weapon = throw_list[throw_index]

	if dbg:
		print("[SWITCH_JET] switch => selected=", p.selected_throw_weapon, " idx=", throw_index, " list=", throw_list)

func _fire_throw_direct():
	if p.combat_mod == null:
		return

	# 1) Rebuild + fix (peut changer lance -> coco)
	_rebuild_throw_list()
	if throw_list.size() == 0:
		p.throw_mode = false
		_update_throw_hud()
		return

	_fix_throw_selection()

	# IMPORTANT : sync HUD AVANT de tirer (sinon selector reste sur l'ancien)
	_update_throw_hud()

	# 2) Tir
	if p.selected_throw_weapon == "coco":
		await p.combat_mod.coco()
	elif p.selected_throw_weapon == "bone":
		await p.combat_mod.bone()
	else:
		await p.combat_mod.lance()

	# 3) Après tir : les compteurs ont peut-être changé => resync sélection + HUD
	_rebuild_throw_list()
	if throw_list.size() == 0:
		p.throw_mode = false
	_update_throw_hud()

func _get_hud():
	return p.game_state.hud

func _update_throw_hud():
	var hud = _get_hud()
	if p.throw_mode:
		hud.show_throw_mode(p.selected_throw_weapon)
	else:
		hud.hide_throw_mode()

func _update_skill_hud_off():
	var hud = _get_hud()
	hud.set_skill_mode(false)

func _update_heal_hud_off():
	var hud = _get_hud()
	hud.hide_heal_mode()
