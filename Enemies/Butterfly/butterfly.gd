extends Node2D

@export var speed = 40.0
@export var move_radius = 80.0
@export var min_dir_time = 0.5
@export var max_dir_time = 2.0
@export var butterfly_color = Color(1, 1, 1, 1)   # couleur modifiable dans l’inspecteur

@onready var sprite = $Sprite
@onready var anim = $AnimationPlayer
@onready var timer = $Timer

var origin_position
var direction = Vector2.ZERO

func _ready():
	# Point de référence pour éviter qu'il parte trop loin
	origin_position = global_position

	# Applique la couleur du papillon depuis l'inspecteur
	sprite.modulate = butterfly_color

	# Animation en boucle
	if anim.has_animation("fly"):
		anim.play("fly")

	# Timer répétitif
	timer.wait_time = randf_range(min_dir_time, max_dir_time)
	timer.start()

	_choose_new_direction()

func _physics_process(delta):
	position += direction * speed * delta

	# Limite de rayon
	var offset = global_position - origin_position
	if offset.length() > move_radius:
		direction = (origin_position - global_position).normalized()

	_update_sprite_facing()

func _on_timer_timeout():
	timer.wait_time = randf_range(min_dir_time, max_dir_time)
	_choose_new_direction()

func _choose_new_direction():
	# Nouvelle direction horizontale + légère variation verticale
	var angle = randf_range(-0.5, 0.5)  
	direction = Vector2(randf_range(-1.0, 1.0), angle).normalized()

func _update_sprite_facing():
	# flip (gauche/droite)
	if direction.x < 0:
		sprite.scale.x = -abs(sprite.scale.x)
	else:
		sprite.scale.x = abs(sprite.scale.x)
