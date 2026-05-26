extends Node2D

@onready var video = $VideoStreamPlayer

func _ready():
	video.play()

func go_to_menu():
	var gs = get_node("/root/GameState")
	gs.load_level("res://Levels/Lvl0/lvl_0.tscn")

func _on_menu_pressed():
	go_to_menu()

func _on_video_stream_player_finished():
	go_to_menu()
