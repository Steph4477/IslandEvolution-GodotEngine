extends Node

# ============================================================================
#                           SWITCH (GENERIC REUTILISABLE)
# ============================================================================
# - Toggle : ouvre/ferme un "mode"
# - Switch : cycle items
# - Fire   : action sur item sélectionné
# - Auto-off : s'éteint quand un autre switch s'active
#
# Props à set depuis le Player :
# - name_id (string) : "throw" / "skill" / "heal" / etc.
# - items (Array) : ["coco","bone","lance"] etc.
# - mode_var (string) : bool dans Player (ex "throw_mode")
# - selected_var (string) : string dans Player (ex "selected_throw_weapon")
# - action_toggle (string)
# - action_switch (string)
# - action_fire (string) (optionnel)
# - group_ref (Array) : liste des autres modules switch (pour auto-off)
#
# Callbacks (méthodes sur Player) :
# - cb_mode(enabled, selected, name_id)
# - cb_changed(selected, name_id)
# - cb_fire(selected, name_id)
# ============================================================================

var p = null
var dbg = false

var name_id = "switch"
var items = []

var mode_var = ""
var selected_var = ""

var action_toggle = ""
var action_switch = ""
var action_fire = ""

var cb_mode = ""
var cb_changed = ""
var cb_fire = ""

var group_ref = []   # autres switch à éteindre quand celui-ci s'active

var _index = 0


func setup(player):
	p = player
	_sync_index_from_player()


func process_input():
	if p == null:
		return

	# TOGGLE
	if action_toggle != "" and Input.is_action_just_pressed(action_toggle):
		_toggle()
		return

	# SWITCH / FIRE uniquement si mode ON
	if mode_var != "":
		if not bool(p.get(mode_var)):
			return

	# SWITCH
	if action_switch != "" and Input.is_action_just_pressed(action_switch):
		_next_item()
		_call_changed()
		return

	# FIRE
	if action_fire != "" and Input.is_action_just_pressed(action_fire):
		_call_fire()
		return


# ============================================================================
#                               API
# ============================================================================
func force_off():
	if p == null:
		return
	if mode_var == "":
		return

	if bool(p.get(mode_var)):
		p.set(mode_var, false)
		_call_mode(false)


func force_on():
	if p == null:
		return
	if mode_var == "":
		return

	if not bool(p.get(mode_var)):
		p.set(mode_var, true)
		_sync_selected_from_index()
		_turn_off_others()
		_call_mode(true)


# ============================================================================
#                               INTERNAL
# ============================================================================
func _toggle():
	if mode_var == "":
		return

	var enabled = not bool(p.get(mode_var))
	p.set(mode_var, enabled)

	if enabled:
		_sync_index_from_player()
		_sync_selected_from_index()
		_turn_off_others()
	else:
		# rien
		pass

	_call_mode(enabled)

	if dbg:
		print("[" + str(name_id).to_upper() + "] TOGGLE -> " + str(enabled) + " selected=" + str(p.get(selected_var)))


func _turn_off_others():
	if group_ref == null:
		return

	for m in group_ref:
		if m == null:
			continue
		if m == self:
			continue
		if m.has_method("force_off"):
			m.force_off()


func _next_item():
	if items.size() <= 0:
		return

	_index += 1
	if _index >= items.size():
		_index = 0

	_sync_selected_from_index()

	if dbg:
		print("[" + str(name_id).to_upper() + "] SWITCH -> selected=" + str(p.get(selected_var)))


func _sync_index_from_player():
	if selected_var == "":
		return
	if items.size() <= 0:
		return

	var current = p.get(selected_var)
	_index = items.find(current)
	if _index == -1:
		_index = 0
		p.set(selected_var, items[_index])


func _sync_selected_from_index():
	if selected_var == "":
		return
	if items.size() <= 0:
		return

	if _index < 0:
		_index = 0
	if _index >= items.size():
		_index = 0

	p.set(selected_var, items[_index])


func _call_mode(enabled):
	if cb_mode == "":
		return
	if not p.has_method(cb_mode):
		return
	p.call(cb_mode, enabled, p.get(selected_var), name_id)


func _call_changed():
	if cb_changed == "":
		return
	if not p.has_method(cb_changed):
		return
	p.call(cb_changed, p.get(selected_var), name_id)


func _call_fire():
	if cb_fire == "":
		return
	if not p.has_method(cb_fire):
		return
	p.call(cb_fire, p.get(selected_var), name_id)
