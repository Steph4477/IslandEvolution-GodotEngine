extends Node

var p
var timer
var fire_buff_time_left = 0.0

func setup(player):
	p = player

	timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = p.fire_buff_duration
	add_child(timer)
	timer.timeout.connect(_on_fire_buff_timeout)

	set_process(false)

func _process(delta):
	if not p.fire_buff_active:
		return

	fire_buff_time_left -= delta

	if fire_buff_time_left < 0.0:
		fire_buff_time_left = 0.0

	if p.game_state and p.game_state.hud:
		p.game_state.hud.update_fire_buff_timer(fire_buff_time_left, p.fire_buff_duration)

func activate_fire_buff():
	p.fire_buff_active = true
	fire_buff_time_left = p.fire_buff_duration

	timer.stop()
	timer.wait_time = p.fire_buff_duration
	timer.start()

	set_process(true)

	if p.game_state and p.game_state.hud:
		p.game_state.hud.show_fire_buff(p.fire_buff_duration)
		p.game_state.hud.update_fire_buff_timer(fire_buff_time_left, p.fire_buff_duration)

func disable_fire_buff():
	p.fire_buff_active = false
	fire_buff_time_left = 0.0
	timer.stop()

	set_process(false)

	if p.game_state and p.game_state.hud:
		p.game_state.hud.hide_fire_buff()

func is_fire_buff_active():
	return p.fire_buff_active

func _on_fire_buff_timeout():
	disable_fire_buff()

func unlock_fire_skill():
	if p.game_state.fire_buff_unlocked:
		return

	p.game_state.fire_buff_unlocked = true

	if p.popups_mod:
		p.popups_mod.show_info("🔥 Skill feu débloqué")
	
	if p.game_state and p.game_state.hud:
		p.game_state.hud.disappear_fire_craft_quest()
