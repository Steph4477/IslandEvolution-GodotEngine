extends Node

var e = null

func setup(enemy):
	e = enemy

func tick(delta):
	if e.is_on_floor():
		return
	e.velocity.y += e.gravity * delta

func on_player_updated(_p):
	pass

func on_hit(_dmg):
	pass

func on_dead():
	pass
