extends StaticBody2D

@export var disappear_delay = 0.2

@onready var anim_player = $AnimationPlayer
@onready var collision = $CollisionShape2D
@onready var timer = $Timer
@onready var plank_full = $Visual/Sprite2D
@onready var left_piece = $Visual/Sprite2D_Left
@onready var right_piece = $Visual/Sprite2D_Right

func _ready():
	timer.one_shot = true
	timer.wait_time = disappear_delay
	plank_full.visible = true
	left_piece.visible = false
	right_piece.visible = false

func _on_detector_body_entered(body):
	if body.is_in_group("Player"):
		anim_player.play("crack")
		timer.start()

func _on_timer_timeout():
	collision.disabled = true
	anim_player.play("disappear")
	await anim_player.animation_finished
	queue_free()
