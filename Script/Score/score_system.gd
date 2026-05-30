extends Node
class_name ScoreSystem

var enemies_killed = 0
var enemies_total = 0


func reset_level_score():
	enemies_killed = 0
	enemies_total = 0


func set_enemies_total(value):
	enemies_total = value


func add_enemy_kill():
	enemies_killed += 1
	print("SCORE - Ennemis tués : ", enemies_killed, "/", enemies_total)


func get_score_data():
	return {
		"enemies_killed": enemies_killed,
		"enemies_total": enemies_total
	}


func load_score_data(data):
	enemies_killed = data.get("enemies_killed", 0)
	enemies_total = data.get("enemies_total", 0)
