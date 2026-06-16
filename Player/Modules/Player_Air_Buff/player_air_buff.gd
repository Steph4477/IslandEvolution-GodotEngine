extends Node

var p
var timer
var air_buff_time_left = 0.0

func setup(player):
	p = player

	timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = p.air_buff_duration
	add_child(timer)
	timer.timeout.connect(_on_air_buff_timeout)

	set_process(false)

func _process(delta):
	if not p.air_buff_active:
		return

	air_buff_time_left -= delta

	if air_buff_time_left < 0.0:
		air_buff_time_left = 0.0

func activate_air_buff():
	p.air_buff_active = true
	air_buff_time_left = p.air_buff_duration

	timer.stop()
	timer.wait_time = p.air_buff_duration
	timer.start()

	set_process(true)

	if p.game_state and p.game_state.hud:
		p.game_state.hud.start_air_cooldown(p.air_buff_duration)

func disable_air_buff():
	p.air_buff_active = false
	air_buff_time_left = 0.0
	timer.stop()

	set_process(false)

func is_air_buff_active():
	return p.air_buff_active

func _on_air_buff_timeout():
	disable_air_buff()

func unlock_air_skill():
	if p.game_state.air_buff_unlocked:
		return

	p.game_state.air_buff_unlocked = true

	if p.popups_mod:
		p.popups_mod.show_info("💨 Skill air débloqué")
	
	if p.game_state and p.game_state.hud:
		p.game_state.hud.disappear_air_craft_quest()
