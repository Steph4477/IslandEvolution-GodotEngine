extends CharacterBody2D

@export var speed = 800.0
@export var lifetime = 10.0
@export var damage = 150

@onready var sprite = $anim
@onready var area = $Area2D

var direction = Vector2.ZERO
var has_collided = false
var is_web = true


func start(spawn_position, dir):
	global_position = spawn_position

	if dir < 0:
		direction = Vector2.LEFT
	else:
		direction = Vector2.RIGHT


func _ready():
	sprite.play("web_attack")
	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _physics_process(_delta):
	velocity = direction * speed
	move_and_slide()


func _on_area_2d_body_entered(body):
	if has_collided:
		return

	if body.is_in_group("Player"):
		has_collided = true
		is_web = true

		var effet_scene = preload("res://Enemies/Tarantula/effects/glued_web.tscn")
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
