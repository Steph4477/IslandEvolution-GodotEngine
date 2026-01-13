extends Node2D

@export var speed = 400.0
@export var wave_amplitude = 8.0
@export var wave_frequency = 1.2
@export var fish_color = Color(1, 1, 1, 1)

# Direction de départ (réglable dans l’inspecteur)
@export var dir_x = 1.0   # 1 = droite, -1 = gauche
@export var dir_y = 0.3   # > 0 monte/descend (mets 0.2 / 0.4 etc.)

@onready var sprite = $Sprite
@onready var anim = $AnimationPlayer
@onready var bounds_col = $SwimBounds/CollisionShape2D

var dir = Vector2.ZERO
var time = 0.0
var last_sin = 0.0
var min_bound = Vector2.ZERO
var max_bound = Vector2.ZERO

func _ready():
	sprite.modulate = fish_color

	if anim.has_animation("fly"):
		anim.play("fly")

	dir = Vector2(dir_x, dir_y).normalized()

	var rect = bounds_col.shape
	var ext = rect.extents
	var center = bounds_col.global_position
	min_bound = center - ext
	max_bound = center + ext

func _physics_process(delta):
	time += delta

	# 1) Déplacement libre (comme papillon)
	global_position += dir * speed * delta

	# 2) Ondulation verticale
	var s = sin(time * TAU * wave_frequency) * wave_amplitude
	global_position.y += s - last_sin
	last_sin = s

	# 3) Rebond + clamp dans la zone
	if global_position.x < min_bound.x:
		global_position.x = min_bound.x
		dir.x = -dir.x
	if global_position.x > max_bound.x:
		global_position.x = max_bound.x
		dir.x = -dir.x

	if global_position.y < min_bound.y:
		global_position.y = min_bound.y
		dir.y = -dir.y
	if global_position.y > max_bound.y:
		global_position.y = max_bound.y
		dir.y = -dir.y

	# 4) Flip sprite
	if dir.x < 0:
		sprite.scale.x = -abs(sprite.scale.x)
	else:
		sprite.scale.x = abs(sprite.scale.x)
