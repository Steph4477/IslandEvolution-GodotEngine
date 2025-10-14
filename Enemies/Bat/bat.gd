extends Node2D

@export var show_duration = 1.0

@onready var sprite = $Sprite2D        
@onready var timer = $Timer
@onready var area = $Area2D

func _ready():
	$Sprite2D.visible = false
	$Timer.one_shot = true

func start_show():
	$Sprite2D.visible = true
	$Sprite2D/AnimationPlayer.play("fly")
	timer.wait_time = show_duration
	timer.start()

func _on_timer_timeout():
	queue_free()

func _on_area_2d_body_entered():
	start_show()
