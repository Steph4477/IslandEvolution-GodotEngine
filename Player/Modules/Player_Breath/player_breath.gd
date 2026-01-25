extends Node

var p

func setup(player):
	p = player

# ============================================================================
#                             API (appelée depuis SwimZone / CollectSkills)
# ============================================================================
func start_underwater_breath():
	p.is_underwater = true
	p.breath_left = p.max_breath

	p.drown_timer.stop()
	update_bubble_rate()

	# Timer respiration (1 tick / seconde)
	if p.breath_tick_timer.is_stopped():
		p.breath_tick_timer.start()

	# Les bulles ne démarrent PAS au début
	p.bubble_timer.stop()

	# HUD
	if p.game_state and p.game_state.hud:
		p.game_state.hud.start_breath(p.max_breath)
		p.game_state.hud.update_breath(p.breath_left, p.max_breath)

func stop_underwater_breath(refill):
	p.is_underwater = false

	p.breath_tick_timer.stop()
	p.bubble_timer.stop()
	p.drown_timer.stop()

	if refill:
		p.breath_left = p.max_breath

	# HUD
	if p.game_state and p.game_state.hud:
		p.game_state.hud.stop_breath()
		p.game_state.hud.update_breath(p.breath_left, p.max_breath)

# ============================================================================
#                             TIMEOUTS (timers)
# ============================================================================
func on_breath_tick_timeout():
	if not p.is_underwater:
		return

	p.breath_left -= 1
	if p.breath_left < 0:
		p.breath_left = 0

	# HUD
	if p.game_state and p.game_state.hud:
		p.game_state.hud.update_breath(p.breath_left, p.max_breath)

	# Démarrage des bulles uniquement à partir de 15s restantes
	if p.breath_left == p.panic_start:
		update_bubble_rate()
		if p.bubble_timer.is_stopped():
			p.bubble_timer.start()

	if p.breath_left == 0:
		p.bubble_timer.stop()
		if p.drown_timer.is_stopped():
			p.drown_timer.start()
		return

	update_bubble_rate()

func on_bubble_timer_timeout():
	if not p.is_underwater:
		return

	# Dès la noyade plus de bulles
	if not p.drown_timer.is_stopped():
		p.bubble_timer.stop()
		return

	if p.breath_left <= 0:
		p.bubble_timer.stop()
		return

	spawn_air_bubble()

func on_drown_timer_timeout():
	if not p.is_underwater:
		return
	if p.breath_left > 0:
		p.drown_timer.stop()
		return

	p.bubble_timer.stop()
	p.modules.damage.on_hit(p.drown_damage_per_second)

# ============================================================================
#                             BUBBLE RATE
# ============================================================================
func update_bubble_rate():
	if p.breath_left > p.panic_start:
		p.bubble_timer.wait_time = p.bubble_interval_normal
		return

	var t = float(p.panic_start - p.breath_left) / float(p.panic_start)
	if t < 0.0:
		t = 0.0
	if t > 1.0:
		t = 1.0

	var w = p.bubble_interval_normal - ((p.bubble_interval_normal - p.bubble_interval_min) * t)
	if w < p.bubble_interval_min:
		w = p.bubble_interval_min

	p.bubble_timer.wait_time = w

# ============================================================================
#                             SPAWN BUBBLE
# ============================================================================
func spawn_air_bubble():
	# Stop net dès que l'air est à 0
	if p.breath_left <= 0:
		return
	if not p.drown_timer.is_stopped():
		return

	var b = p.air_bubble_scene.instantiate()
	p.get_parent().add_child(b)
	b.global_position = p.air_bubble_spawn.global_position

	# bouche ouverte pendant la noyade à chaque spawn de bulle
	if p.open_mouth:
		p.open_mouth.visible = true
		p.close_mouth.visible = false
		await p.get_tree().create_timer(p.mouth_show_time).timeout
		if p.open_mouth:
			p.open_mouth.visible = false
			p.close_mouth.visible = true
