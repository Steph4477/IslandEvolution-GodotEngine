extends Node2D

var attached_player = null
var expect_exit = false
var angle_direction = 0

@onready var anim = $AnimationPlayer
@onready var collision_shape = $Pivot/Area2D/CollisionShape2D


func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		attached_player = body
		body.movement_mod.attach_to_liana(self)
		expect_exit = false
		anim.play("retract")


func _on_area_2d_body_exited(body):
	if body == attached_player and expect_exit:
		attached_player = null
		expect_exit = false
		anim.play("unroll")


func on_player_attach():
	pass


func on_player_detach():
	attached_player = null
	anim.play("unroll")


func disable_collision_temporarily(time = 0.3):
	collision_shape.disabled = true
	await get_tree().create_timer(time).timeout
	collision_shape.disabled = false
