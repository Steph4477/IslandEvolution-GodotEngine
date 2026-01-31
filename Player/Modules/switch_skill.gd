# res://Player/Modules/switch_skill.gd
extends Node

# ============================================================================
#                          SWITCH SKILL (K / switch)
# ============================================================================
# 1) "skill_mode" : ouvre le mode skill (K via InputMap)
# 2) "skill_switch" : navigue dans ["camouflage","sprint","ramp"]
#
# IMPORTANT :
# - Un seul mode actif à la fois : ouvrir K coupe J (throw_mode=false)
# - "switch" est partagé, donc on force l'exclusivité.
#
# Dépendances Player :
# - p.INPUT["skill_mode"], p.INPUT["skill_switch"]
# - p.skill_mode (bool)
# - p.selected_skill (string)
# - p.throw_mode (bool)
# - p.game_state.skill_selected (persist)
# - HUD : set_skill_mode(bool) + set_skill_selected(string) + hide_throw_mode()
# ============================================================================

var p = null
var dbg = true

var skill_list = ["camouflage", "sprint", "ramp"]
var skill_index = 0

func setup(player):
	p = player

	# Sync index depuis la sélection actuelle
	skill_index = skill_list.find(p.selected_skill)
	if skill_index == -1:
		skill_index = 0
		p.selected_skill = skill_list[0]

	_update_skill_hud()

func update_input():
	if p == null:
		return

	# 1) K : ouvre le mode skill (conserve dernière sélection)
	if Input.is_action_just_pressed(p.INPUT["skill_mode"]):
		_enable_skill_mode()
		return

	if not p.skill_mode:
		return

	# 2) switch : navigue
	if Input.is_action_just_pressed(p.INPUT["skill_switch"]):
		_cycle_skill()
		_persist_skill_selected()
		_update_skill_hud()
		return

# ============================================================================
#                                 CORE
# ============================================================================

func _enable_skill_mode():
	# Un seul mode actif : si on passe en skill, on coupe jet
	if p.throw_mode:
		p.throw_mode = false
		_update_throw_hud_off()

	# K ouvre juste le mode skill (pas toggle)
	if p.skill_mode:
		_update_skill_hud()
		return

	p.skill_mode = true

	# recalage index
	skill_index = skill_list.find(p.selected_skill)
	if skill_index == -1:
		skill_index = 0
		p.selected_skill = skill_list[0]

	_persist_skill_selected()
	_update_skill_hud()

func _cycle_skill():
	skill_index += 1
	if skill_index >= skill_list.size():
		skill_index = 0

	p.selected_skill = skill_list[skill_index]

func _persist_skill_selected():
	if p.game_state:
		p.game_state.skill_selected = p.selected_skill

# ============================================================================
#                                   HUD
# ============================================================================

func _get_main_hud():
	if p.game_state:
		return p.game_state.hud
	return null

func _update_skill_hud():
	var hud = _get_main_hud()
	if hud == null:
		return

	hud.set_skill_mode(p.skill_mode)
	if p.skill_mode:
		hud.set_skill_selected(p.selected_skill)

func _update_throw_hud_off():
	var hud = _get_main_hud()
	if hud == null:
		return
	# API HUD jet déjà en place chez toi
	hud.hide_throw_mode()
