extends Node

var p = null
var gs = null

var skill_mode = false
var skill_selected = "ramp" # "ramp" | "sprint" | "camouflage"


func setup(player):
	p = player

	# GameState
	if p and p.game_state:
		gs = p.game_state
	else:
		gs = get_node_or_null("/root/GameState")

	# restore sélection persistée
	if gs:
		if "skill_selected" in gs:
			if gs.skill_selected != "":
				gs.skill_selected = gs.skill_selected

	_ensure_valid_selection()

	print("[SKILL][READY] start | skill_mode=" + str(skill_mode) + " selected=" + str(skill_selected))
	_update_skill_hud()


func force_close():
	if skill_mode:
		skill_mode = false
		print("[SKILL] force_close -> skill_mode=false")
		_update_skill_hud()


func toggle_skill_mode():
	skill_mode = not skill_mode

	if skill_mode:
		if p and p.throw_mod:
			p.throw_mod.force_close()

		_ensure_valid_selection()

	_update_skill_hud()



func set_skill_selected(s):
	skill_selected = s

	if gs:
		if "skill_selected" in gs:
			gs.skill_selected = skill_selected

	print("[SKILL] set_skill_selected -> " + str(skill_selected))
	_update_skill_hud()


func _update_skill_hud():
	if gs and gs.hud:
		print("[SKILL][HUD] update: skill_mode=" + str(skill_mode) + " selected=" + str(skill_selected))
		if gs.hud.has_method("set_skill_mode"):
			gs.hud.set_skill_mode(skill_mode)

		if gs.hud.has_method("set_skill_selected"):
			gs.hud.set_skill_selected(skill_selected)


func update_input():
	if Input.is_action_just_pressed("skill_mode"):
		print("[SKILL][INPUT] skill_mode pressed (K)")
		toggle_skill_mode()
		return

	# IMPORTANT : hors mode skills, on ne consomme PAS switch / space
	if not skill_mode:
		return

	if Input.is_action_just_pressed("throw_switsh"):
		print("[SKILL][INPUT] throw_switch pressed (switch)")
		_cycle_skill()
		return

	if Input.is_action_just_pressed("throw_fire"):
		print("[SKILL][INPUT] throw_fire pressed (space)")
		_fire_selected_skill()
		return


# ============================================================================
#                         SELECTION / DISPONIBILITÉ
# ============================================================================

func _get_available_skills():
	var list = []

	if gs and gs.ramp_unlocked:
		list.append("ramp")

	if gs and gs.sprint_unlocked:
		list.append("sprint")

	if gs and gs.camouflage_unlocked:
		list.append("camouflage")

	return list



func _cycle_skill():
	var list = _get_available_skills()
	print("[SKILL] available=" + str(list))

	if list.size() == 0:
		return

	var idx = list.find(skill_selected)
	if idx == -1:
		set_skill_selected(list[0])
		return

	idx += 1
	if idx >= list.size():
		idx = 0

	set_skill_selected(list[idx])


# ============================================================================
#                                FIRE
# ============================================================================
func _ensure_valid_selection():
	var list = _get_available_skills()
	if list.size() == 0:
		return

	# si la sélection actuelle est invalide → on prend la 1ère dispo
	if list.find(skill_selected) == -1:
		skill_selected = list[0]
		if gs:
			gs.skill_selected = skill_selected

func _fire_selected_skill():
	print("[SKILL] fire_selected -> " + str(skill_selected))

	# ⚠️ Remplace ces appels par TES fonctions exactes si besoin.
	if skill_selected == "ramp":
		p.player_skills.process_ramp()

	elif skill_selected == "sprint":
		p.player_skills.process_sprint()

	elif skill_selected == "camouflage":
		p.player_skills.use_camouflage()
