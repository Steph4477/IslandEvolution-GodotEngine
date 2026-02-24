extends Node

var e = null
var gs = null
var last_player = null

func setup(enemy):
	e = enemy
	gs = get_node("/root/GameState")

func tick(_delta):
	var p = gs.player
	if p != last_player:
		last_player = p
		e.set_player(p)

func on_player_updated(_p):
	pass

func on_hit(_dmg):
	pass

func on_dead():
	pass
