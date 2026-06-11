extends CharacterBody2D

@export var speed = 800.0
@export var lifetime = 10.0

@onready var sprite = $anim
@onready var area = $Area2D
@onready var shape = $Area2D/CollisionShape2D

var direction = Vector2.ZERO
var has_collided = false
var is_web = true
var damage = 0

func _ready():
	top_level = true
	z_index = 100
	visible = true

	sprite.visible = true
	sprite.z_index = 100
	sprite.play("web_attack")

	if shape:
		shape.disabled = true

	await get_tree().create_timer(lifetime).timeout
	queue_free()

func start(spawn_position, dir, projectile_damage):
	damage = projectile_damage
	global_position = spawn_position

	if typeof(dir) == TYPE_VECTOR2:
		direction = dir.normalized()
	else:
		if dir < 0:
			direction = Vector2.LEFT
		else:
			direction = Vector2.RIGHT

	await get_tree().create_timer(0.15).timeout

	if shape:
		shape.disabled = false

func _physics_process(_delta):
	velocity = direction * speed
	move_and_slide()

func _on_area_2d_body_entered(body):
	if has_collided:
		return

	if not body.is_in_group("Player"):
		return

	has_collided = true
	is_web = true

	var effet_scene = preload("res://Enemies/Tarantula/Effects/glued_web.tscn")
	var effet = effet_scene.instantiate()

	get_tree().current_scene.add_child(effet)
	effet.global_position = global_position
	effet.get_node("AnimationPlayer").play("appear_fade")

	if body.effects_mod.has_method("apply_web_effect"):
		body.effects_mod.apply_web_effect()

	if body.damage_mod.has_method("on_hit"):
		body.damage_mod.on_hit(damage)

	var gs = get_node("/root/GameState")
	if gs.hud:
		gs.hud.spawn_hud_dirt()

	queue_free()
