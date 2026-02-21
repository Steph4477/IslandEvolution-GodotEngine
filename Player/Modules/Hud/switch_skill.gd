extends Node

var p = null
var dbg = true

var skill_list = ["ramp", "sprint", "camouflage"]
var skill_index = 0

func setup(player):
	p = player

	skill_index = skill_list.find(p.selected_skill)
	if skill_index == -1:
		skill_index = 0
		p.selected_skill = skill_list[0]

	if dbg:
		print("[SWITCH_SKILL][READY] skill_mode=", p.skill_mode, " selected=", p.selected_skill, " idx=", skill_index)

func update_input():
	if p == null:
		return

	if Input.is_action_just_pressed(p.INPUT["skill_mode"]):
		p.skill_mode = not p.skill_mode

		if dbg:
			print("[SWITCH_SKILL] skill_mode pressed =>", p.skill_mode, " selected=", p.selected_skill)

		_update_skill_hud()

	if p.skill_mode and Input.is_action_just_pressed(p.INPUT["skill_switch"]):
		skill_index = (skill_index + 1) % skill_list.size()
		p.selected_skill = skill_list[skill_index]

		if dbg:
			print("[SWITCH_SKILL] switch => selected=", p.selected_skill, " idx=", skill_index)

		_update_skill_hud()

func _update_skill_hud():
	if p == null:
		return

	var gs = p.game_state
	if gs == null:
		if dbg:
			print("[SWITCH_SKILL][HUD] game_state NULL")
		return

	var hud = gs.hud
	if hud == null:
		if dbg:
			print("[SWITCH_SKILL][HUD] hud NULL (gs.hud)")
		return

	if p.skill_mode:
		if hud.has_method("show_skill_mode"):
			hud.show_skill_mode(p.selected_skill)
	else:
		if hud.has_method("hide_skill_mode"):
			hud.hide_skill_mode()
