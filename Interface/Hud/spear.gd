extends TouchScreenButton

@export var start_enabled = false  # ← OFF par défaut au lancement

func _ready():
	add_to_group("lance_button")  # pratique pour le retrouver
	if start_enabled:
		enable_lance_button()
	else:
		disable_lance_button()

func enable_lance_button():
	# visuel
	modulate = Color(1, 1, 1, 1)
	# collision
	var shape = get_node_or_null("CollisionShape2D")
	if shape == null:
		shape = find_child("CollisionShape2D", true, false)
	if shape:
		shape.disabled = false
	# action input
	if action == "":
		action = "shoot"

func disable_lance_button():
	modulate = Color(1, 1, 1, 0.4)
	var shape = get_node_or_null("CollisionShape2D")
	if shape == null:
		shape = find_child("CollisionShape2D", true, false)
	if shape:
		shape.disabled = true
	action = ""  # coupe totalement l'input
