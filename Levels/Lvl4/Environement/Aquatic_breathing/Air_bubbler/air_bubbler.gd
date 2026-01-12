extends Node2D

@export var bubble_scene = preload("res://Levels/Lvl4/Environement/Aquatic_breathing/Plants/air_bubble.tscn")
@export var spawn_interval = 0.4
@export var burst_spacing = 0.05

@onready var spawn_timer = $SpawnTimer
@onready var emitters = $Emitters.get_children()

func _ready():
	spawn_timer.wait_time = spawn_interval
	spawn_timer.start()

func _on_spawn_timer_timeout():
	for emitter in emitters:
		_spawn_from_emitter(emitter)

func _spawn_from_emitter(emitter):
	await get_tree().create_timer(burst_spacing).timeout

	var b = bubble_scene.instantiate()
	get_parent().add_child(b)
	b.global_position = emitter.global_position
