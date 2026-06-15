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
	await gs.restart_game()


func _on_load_pressed():
	await gs.load_save()


func _on_save_pressed():
	gs.save_game()

func _on_continue_pressed():
	await gs.continue_game()


func _on_quitter_pressed():
	get_tree().quit()
