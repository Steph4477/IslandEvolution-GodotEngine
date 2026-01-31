extends Node

var p = null
var gs = null

var throw_mode = false
var throw_weapon = "coco" # "coco" | "lance" | "bone"


func setup(player):
	p = player

	# GameState
	if p and p.game_state:
		gs = p.game_state
	else:
		gs = get_node_or_null("/root/GameState")

	# restore sélection persistée si dispo
	if gs:
		if "throw_weapon" in gs:
			if gs.throw_weapon != "":
				throw_weapon = gs.throw_weapon

	_update_throw_hud()


func force_close():
	if throw_mode:
		throw_mode = false
		_update_throw_hud()


func toggle_throw_mode():
	throw_mode = not throw_mode

	# Si on ouvre le mode jet, on ferme le mode skills
	if throw_mode:
		if p and p.skill_select_mod:
			p.skill_select_mod.force_close()

	_update_throw_hud()


func set_throw_weapon(w):
	throw_weapon = w

	if gs:
		if "throw_weapon" in gs:
			gs.throw_weapon = throw_weapon

	_update_throw_hud()


func _update_throw_hud():
	if gs and gs.hud:
		if gs.hud.has_method("set_throw_mode"):
			gs.hud.set_throw_mode(throw_mode)

		if gs.hud.has_method("set_throw_weapon"):
			gs.hud.set_throw_weapon(throw_weapon)


func update_input():
	# J : ouvre/ferme le mode jet (garde la dernière arme)
	if Input.is_action_just_pressed("throw_mode"):
		toggle_throw_mode()
		return

	# IMPORTANT : hors mode jet, on ne consomme PAS switch / space
	if not throw_mode:
		return

	# switch : sélection arme
	if Input.is_action_just_pressed("throw_switch"):
		_cycle_throw_weapon()
		return

	# space : tir arme sélectionnée
	if Input.is_action_just_pressed("throw_fire"):
		_fire_selected_weapon()
		return


# ============================================================================
#                         SELECTION / DISPONIBILITÉ
# ============================================================================

func _get_available_weapons():
	var list = []

	if _can_throw_coco():
		list.append("coco")

	if _can_throw_lance():
		list.append("lance")

	if _can_throw_bone():
		list.append("bone")

	return list


func _cycle_throw_weapon():
	var list = _get_available_weapons()
	if list.size() == 0:
		return

	var idx = list.find(throw_weapon)
	if idx == -1:
		set_throw_weapon(list[0])
		return

	idx += 1
	if idx >= list.size():
		idx = 0

	set_throw_weapon(list[idx])


func _can_throw_coco():
	if gs:
		if gs.can_fire_coco:
			return true
		if gs.coco_count > 0:
			return true
	return false


func _can_throw_lance():
	if gs:
		if gs.can_fire_lance:
			return true
		if gs.lance_count > 0:
			return true
	return false


func _can_throw_bone():
	if gs:
		if gs.can_fire_bone:
			return true
		if gs.bone_count > 0:
			return true
	return false


# ============================================================================
#                                FIRE
# ============================================================================

func _fire_selected_weapon():
	# ⚠️ Tes tirs marchent déjà : ici on appelle des méthodes “standards”.
	# Si tes noms sont différents, remplace juste les 3 appels ci-dessous.

	if throw_weapon == "coco":
		if p.has_method("fire_coco"):
			p.fire_coco()
		elif p.has_method("shoot_coco"):
			p.shoot_coco()

	elif throw_weapon == "lance":
		if p.has_method("fire_lance"):
			p.fire_lance()
		elif p.has_method("shoot_lance"):
			p.shoot_lance()

	elif throw_weapon == "bone":
		if p.has_method("fire_bone"):
			p.fire_bone()
		elif p.has_method("shoot_bone"):
			p.shoot_bone()
