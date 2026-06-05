extends Node2D

@onready var toucan_dialogue = $ToucanDialogue

var gs
var player = null

func _ready():
	$sound/dijee.play()
	gs = get_node("/root/GameState")
	gs.load_global_progress()
	refresh_difficulty_buttons()


func refresh_difficulty_buttons():
	$DifficultyButtons/Unlocked/Explorer.visible = true

	$DifficultyButtons/Unlocked/Survivor.visible = gs.survivor_unlocked
	$DifficultyButtons/Locked/Survivor.visible = not gs.survivor_unlocked

	$DifficultyButtons/Unlocked/King.visible = gs.king_unlocked
	$DifficultyButtons/Locked/King.visible = not gs.king_unlocked


func _on_options_pressed():
	gs.load_level("res://Interface/Configuration/configuration.tscn")


func _on_restart_pressed():
	gs.reset_progression()
	gs.reset_lives()
	gs.reinitialise()
	gs.reset_session_dialogues()
	gs.save_game()
	gs.load_level("res://Levels/Lvl1/lvl_1.tscn")


func _on_load_pressed():
	await gs.load_game()
	refresh_difficulty_buttons()


func _on_save_pressed():
	gs.save_game()

func _on_continue_pressed():
	await gs.load_game()
	gs.difficulty = gs.get_continue_difficulty()
	gs.save_game()


func _on_quitter_pressed():
	get_tree().quit()
