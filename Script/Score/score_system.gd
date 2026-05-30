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

# --- Compte récursivement tous les ennemis présents sous un node ---
func count_enemies_in_node(node):
	var total = 0

	for child in node.get_children():
		if child is CharacterBody2D:
			total += 1
		else:
			total += count_enemies_in_node(child)

	return total

func print_level_stats():
	print("=== SCORE NIVEAU ===")
	print("Ennemis tués : ", enemies_killed, " / ", enemies_total)
