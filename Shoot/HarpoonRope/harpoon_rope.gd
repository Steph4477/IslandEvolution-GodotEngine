extends Node2D
class_name HarpoonRope

var point_shooter = null
var point_target = null

var segment_count = 30

# Effet courbe Relâchement de la corde
var sag = 18.0

# Liste des morceaux de corde
var segments = []

# Texture utilisée par les morceaux
@onready var rope_texture = preload("res://Shoot/HarpoonRope/harpoon_rope.png")

# ============================================================================
#                                START
# ============================================================================

func start(a, b):
	point_shooter = a
	point_target = b

	# Crée tous les morceaux de corde
	for i in range(segment_count):

		var sprite = Sprite2D.new()

		sprite.texture = rope_texture
		sprite.scale = Vector2(0.25, 0.15)

		add_child(sprite)

		segments.append(sprite)

# ============================================================================
#                              UPDATE ROPE
# ============================================================================

func update_rope():
	var start_pos = point_shooter.global_position
	var end_pos = point_target.global_position

	# Point du milieu
	var middle = (start_pos + end_pos) / 2.0

	# Ajoute le relâchement
	middle.y += sag

	# Place tous les morceaux
	for i in range(segment_count):

		# Progression sur la corde
		var t = float(i) / float(segment_count)

		# Première interpolation
		var p1 = start_pos.lerp(middle, t)

		# Deuxième interpolation
		var p2 = middle.lerp(end_pos, t)

		# Position finale du morceau
		var pos = p1.lerp(p2, t)

		# Petit point suivant pour la rotation
		var next_t = t + 0.02

		var np1 = start_pos.lerp(middle, next_t)
		var np2 = middle.lerp(end_pos, next_t)

		var next_pos = np1.lerp(np2, next_t)

		# Place le sprite
		segments[i].global_position = pos

		# Oriente le sprite
		segments[i].rotation = pos.direction_to(next_pos).angle()

# ============================================================================
#                                  STOP
# ============================================================================

func stop():
	queue_free()
