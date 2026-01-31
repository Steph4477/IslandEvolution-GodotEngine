# res://Player/Modules/switch_jet.gd
extends Node

# ============================================================================
#                           SWITCH JET (J / switch / space)
# ============================================================================
# 1) "throw_mode" : ouvre le mode jet (J via InputMap)
# 2) "throw_switch" : navigue dans ["lance","coco","bone"]
# 3) "throw_fire" : tire l'arme sélectionnée (space via InputMap)
#
# IMPORTANT :
# - Un seul mode actif à la fois : ouvrir J coupe K (skill_mode=false)
# - "switch" est partagé entre les 2 modes, donc on force l'exclusivité.
#
# Dépendances Player :
# - p.INPUT["throw_mode"], p.INPUT["throw_switch"], p.INPUT["throw_fire"]
# - p.throw_mode (bool)
# - p.selected_throw_weapon (string)
# - p.skill_mode (bool)
# - p.combat_mod.coco() / bone() / lance()
# - HUD : show_throw_mode(weapon) / hide_throw_mode() / flash_throw_group()
# - HUD skill : set_skill_mode(bool)
# ============================================================================

var p = null
var dbg = true

var throw_list = ["lance", "coco", "bone"]
var throw_index = 0

func setup(player):
	p = player

	# Sync index depuis la sélection actuelle du player
	throw_index = throw_list.find(p.selected_throw_weapon)
	if throw_index == -1:
		throw_index = 0
		p.selected_throw_weapon = throw_list[0]

	# Clean HUD si throw_mode=false
	_update_throw_hud()

	if dbg:
		print("[SWITCH_JET][READY] throw_mode=", p.throw_mode, " selected=", p.selected_throw_weapon, " idx=", throw_index)

func update_input():
	if p == null:
		return

	# 1) J : ouvre le mode jet (conserve dernière arme)
	if Input.is_action_just_pressed(p.INPUT["throw_mode"]):
		if dbg:
			print("[SWITCH_JET][INPUT] throw_mode pressed => open mode (keep selected=", p.selected_throw_weapon, ")")
		_enable_throw_mode()
		return

	# Si pas en mode jet, rien d’autre ne répond
	if not p.throw_mode:
		return

	# 2) switch : navigue
	if Input.is_action_just_pressed(p.INPUT["throw_switch"]):
		_cycle_throw_weapon()
		_update_throw_hud()
		return

	# 3) space : tire
	if Input.is_action_just_pressed(p.INPUT["throw_fire"]):
		_fire_selected_throw_weapon()
		return

# ============================================================================
#                                 CORE
# ============================================================================

func _enable_throw_mode():
	# Un seul mode actif : si on passe en jet, on coupe skill
	if p.skill_mode:
		p.skill_mode = false
		_update_skill_hud_off()

	# J ouvre juste le mode jet (pas toggle)
	if p.throw_mode:
		if dbg:
			print("[SWITCH_JET] enable: already ON | selected=", p.selected_throw_weapon)
		_flash_throw_group()
		return

	p.throw_mode = true

	# recalage index
	throw_index = throw_list.find(p.selected_throw_weapon)
	if throw_index == -1:
		throw_index = 0
		p.selected_throw_weapon = throw_list[0]

	if dbg:
		print("[SWITCH_JET] enable: ACTIVATED | selected=", p.selected_throw_weapon, " idx=", throw_index)

	_update_throw_hud()
	_flash_throw_group()

func _cycle_throw_weapon():
	var before = p.selected_throw_weapon

	throw_index += 1
	if throw_index >= throw_list.size():
		throw_index = 0

	p.selected_throw_weapon = throw_list[throw_index]

	if dbg:
		print("[SWITCH_JET] switch ", before, " -> ", p.selected_throw_weapon, " idx=", throw_index)

func _fire_selected_throw_weapon():
	if p.combat_mod == null:
		if dbg:
			print("[SWITCH_JET] FIRE BLOCKED: combat_mod=null")
		return

	if dbg:
		print("[SWITCH_JET] FIRE OK -> ", p.selected_throw_weapon)

	if p.selected_throw_weapon == "coco":
		p.combat_mod.coco()
	elif p.selected_throw_weapon == "bone":
		p.combat_mod.bone()
	else:
		p.combat_mod.lance()

# ============================================================================
#                                   HUD
# ============================================================================

func _get_main_hud():
	if p.game_state:
		return p.game_state.hud
	return null

func _update_throw_hud():
	var hud = _get_main_hud()
	if hud == null:
		if dbg:
			print("[SWITCH_JET][HUD] HUD NULL (game_state.hud)")
		return

	if dbg:
		print("[SWITCH_JET][HUD] update: throw_mode=", p.throw_mode, " selected=", p.selected_throw_weapon)

	if p.throw_mode:
		hud.show_throw_mode(p.selected_throw_weapon)
	else:
		hud.hide_throw_mode()

func _flash_throw_group():
	var hud = _get_main_hud()
	if hud == null:
		if dbg:
			print("[SWITCH_JET][HUD] flash: HUD NULL")
		return

	hud.flash_throw_group()

func _update_skill_hud_off():
	var hud = _get_main_hud()
	if hud == null:
		return
	# API HUD skills déjà existante chez toi
	hud.set_skill_mode(false)
