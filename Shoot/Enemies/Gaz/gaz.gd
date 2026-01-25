extends CharacterBody2D

@export var speed := 800.0
@export var lifetime := 10.0
@onready var anim = $AnimationPlayer
@onready var area = $Area2D
var damage = 400

var direction: Vector2 = Vector2.ZERO
var has_collided = false

func _ready():
	anim.play("attaque_gaz")
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(_delta):
	velocity = direction * speed
	move_and_slide()


func _on_area_2d_body_entered(body: Node2D) -> void:
	queue_free()
	if body.is_in_group("Player"):
		has_collided = true
		
		# Applique l’effet au joueur

		body.effects_mod.apply_gaz()
		
		# Applique les dégâts 
		queue_free()
		if body.damage_mod.has_method("on_hit"):
			body.damage_mod.on_hit(damage)
