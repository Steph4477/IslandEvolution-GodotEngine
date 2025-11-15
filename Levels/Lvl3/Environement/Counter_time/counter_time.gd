extends Node2D

func _ready():
	$"3".visible = false
	$"2".visible = false
	$"1".visible = false
	$"Go!".visible = false
	$AnimationPlayer.play("counter_time")
