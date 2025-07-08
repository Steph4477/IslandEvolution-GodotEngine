extends Node2D

func _ready():
	# 🔁 Récupère le GameState à la racine du projet
	var game_state = get_node("/root/GameState")

	# 🔢 Compte les graines (enfants directs de ce noeud)
	var nombre_graines = get_child_count()
	game_state.reset_seed_tracking(nombre_graines)

	# 🔍 Cherche le totem directement dans la scène lvl1
	var totem = get_node_or_null("/root/GameState/lvl1/Totem")

	# ✅ Si trouvé, connecte le signal
	if totem.has_method("on_all_seeds_collected"):
		game_state.connect("all_seeds_collected", Callable(totem, "on_all_seeds_collected"))
