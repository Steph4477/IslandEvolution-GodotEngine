extends Node
class_name ScoreSystem

var enemies_killed = 0
var enemies_total = 0
var stars = 0


##################################################################################
#                                CALCUL D'ENEMIS TUES                            #
##################################################################################

func reset_level_score():
	enemies_killed = 0
	enemies_total = 0
	stars = 0

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
	print("Étoiles : ", stars)
	print("SCORE - Médaille : ", get_medal())
	
##################################################################################
#                                CALCUL ETOILES                                  #
##################################################################################
func calculate_stars():
	var percent = get_kill_percent()

	if percent >= 100:
		stars = 3
	elif percent >= 80:
		stars = 2
	elif percent >= 50:
		stars = 1
	else:
		stars = 0
	
	print("SCORE - Pourcentage :", percent)
	print("SCORE - Etoiles :", stars)
	print("SCORE - Médaille : ", get_medal())

##################################################################################
#                                CALCUL DE LA MEDAILLE                           #
##################################################################################
func get_medal():
	if stars == 3:
		return "gold"

	if stars == 2:
		return "silver"

	if stars == 1:
		return "bronze"

	return "banana"

##################################################################################
#                                CALCUL EVOLUTION                                #
##################################################################################
func get_kill_percent():
	if enemies_total <= 0:
		return 0

	return int(round(float(enemies_killed) / float(enemies_total) * 100.0))


func get_moko_evolution_bonus():
	var percent = get_kill_percent()

	if percent >= 100:
		return 10

	if percent >= 80:
		return 8

	if percent >= 50:
		return 6

	return 2


func get_enemy_evolution_bonus():
	return 12


func get_moko_damage_multiplier(total_bonus_percent):
	return 1.0 + float(total_bonus_percent) / 100.0

func get_player_damage(base_damage, total_bonus_percent):
	return int(round(base_damage * get_moko_damage_multiplier(total_bonus_percent)))


func get_moko_hp_multiplier(total_bonus_percent):
	return 1.0 + float(total_bonus_percent) / 100.0


func get_enemy_evolution_multiplier(total_bonus_percent):
	return 1.0 + float(total_bonus_percent) / 100.0
