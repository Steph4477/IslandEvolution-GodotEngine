extends Node2D

@export var speed = 900                 # vitesse du projectile
@export var max_distance = 800          # portée
@export var damage = 40                 # dégâts à l'impact
@export var start_offset = Vector2(56, -16)  # petit décalage depuis la bouche

# Déformations (tu peux ajuster)
@export var fly_stretch_x = 1.5         # étirement horizontal en vol
@export var fly_stretch_y = 0.8         # écrasement vertical en vol
@export var wobble_amount = 0.12        # amplitude du wobble (respiration)
@export var wobble_speed = 6.0          # vitesse du wobble
@export var impact_squash_x = 0.4       # squish horizontal à l'impact
@export var impact_squash_y = 1.8       # squish vertical à l'impact
@export var impact_fade_time = 0.18     # durée du fade-out

var direction = Vector2.RIGHT           # défini à l'instanciation
var traveled = 0.0
var did_hit = false

@onready var spr = $Sprite2D
@onready var hitbox = $Hitbox
@onready var shape = $Hitbox/CollisionShape2D
@onready var life_timer = $LifeTimer

func _ready():
	# hitbox rect simple alignée avec le sprite
	var r = RectangleShape2D.new()
	r.size = Vector2(64, 28)
	shape.shape = r
	hitbox.position = Vector2(0, 0)

	# connexions
	hitbox.connect("body_entered", Callable(self, "_on_hitbox_body_entered"))
	life_timer.connect("timeout", Callable(self, "_on_life_timeout"))

	# orientation
	var dir_x = 1
	if direction.x < 0:
		dir_x = -1
	scale.x = abs(scale.x) * dir_x

	# position de départ (en local par rapport à la grenouille si add_child au même parent)
	position += Vector2(start_offset.x * dir_x, start_offset.y)

	# durée de vie auto selon distance et vitesse
	var life = float(max_distance) / float(speed)
	life_timer.wait_time = life
	life_timer.start()

	# pose de départ et wobble en vol
	_set_fly_pose()
	_start_wobble()

	set_physics_process(true)

func _physics_process(delta):
	if did_hit:
		return

	var move = direction * speed * delta
	position += move
	traveled += move.length()

	# petit alignement visuel (optionnel): incliner selon la vitesse
	rotation = direction.angle()

	if traveled >= max_distance:
		_finish()

func _set_fly_pose():
	# étirement léger en vol
	spr.scale = Vector2(fly_stretch_x, fly_stretch_y)
	modulate = Color(1, 1, 1, 1)

func _start_wobble():
	# wobble simple en boucle (respiration gluante)
	var tw = create_tween()
	tw.set_loops(0) # infini
	tw.tween_property(spr, "scale:y", fly_stretch_y + wobble_amount, 0.5 / wobble_speed)
	tw.tween_property(spr, "scale:y", fly_stretch_y - wobble_amount, 0.5 / wobble_speed)

func _impact_anim():
	# stop mouvement et dégâts
	did_hit = true
	set_physics_process(false)

	# squish + fade
	var tw = create_tween()
	tw.tween_property(spr, "scale", Vector2(impact_squash_x, impact_squash_y), impact_fade_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "modulate:a", 0.0, impact_fade_time)
	tw.tween_callback(Callable(self, "_finish"))

func _finish():
	queue_free()

func _on_hitbox_body_entered(body):
	if did_hit:
		return
	if is_instance_valid(body) and body.is_in_group("Player"):
		body.on_hit(damage)
		_impact_anim()
	 # Application de l'effet gaz de moko
	if body.has_method("apply_gaz"):
			body.apply_gaz() 

func _on_life_timeout():
	_finish()
