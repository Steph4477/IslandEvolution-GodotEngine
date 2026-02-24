extends CharacterBody2D
# EnemyGroundBase : orchestre des modules + hooks communs (sol)

@export var max_hp = 100
@export var gravity = 2000

var gs = null
var player = null

var hp = 0
var is_dead = false
var facing = 1

# simple flags réutilisables
var player_detected = false

var mods = []

func _ready():
	gs = get_node("/root/GameState")
	hp = max_hp

	_collect_modules()
	_setup_modules()

func _physics_process(delta):
	if is_dead:
		return

	for m in mods:
		m.tick(delta)

	move_and_slide()

func _collect_modules():
	mods.clear()
	var holder = get_node_or_null("Modules")
	if holder == null:
		return

	for c in holder.get_children():
		mods.append(c)

func _setup_modules():
	for m in mods:
		m.setup(self)

func set_player(p):
	player = p
	for m in mods:
		m.on_player_updated(p)

func on_hit(dmg):
	if is_dead:
		return

	hp -= dmg
	if hp < 0:
		hp = 0

	for m in mods:
		m.on_hit(dmg)

	if hp <= 0:
		die()

func die():
	if is_dead:
		return

	is_dead = true

	for m in mods:
		m.on_dead()

	queue_free()

func set_facing(dir):
	if dir == 0:
		return

	facing = dir

	var rot = get_node_or_null("Rotator")
	if rot:
		rot.scale.x = abs(rot.scale.x) * facing

func _on_detect_area_body_entered(body):
	if body == player:
		player_detected = true

func _on_detect_area_body_exited(body):
	if body == player:
		player_detected = false
