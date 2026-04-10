extends Node

var p
var timer

func setup(player):
	p = player

	timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = p.fire_buff_duration
	add_child(timer)
	timer.timeout.connect(_on_fire_buff_timeout)

func activate_fire_buff():
	p.fire_buff_active = true
	timer.stop()
	timer.wait_time = p.fire_buff_duration
	timer.start()

func disable_fire_buff():
	p.fire_buff_active = false
	timer.stop()

func is_fire_buff_active():
	return p.fire_buff_active

func _on_fire_buff_timeout():
	disable_fire_buff()
