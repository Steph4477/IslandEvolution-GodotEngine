extends Node2D

@onready var boss = $Tarantula

var cam
var player

func _ready():
	$Node2D/Sound/lvl2.play()
	
	await get_tree().process_frame

	var gs = get_node("/root/GameState")

	player = gs.player
	cam = player.get_node("Camera2D")

	boss.set_meta("boss_portrait", preload("res://Hud/BossHud/HudFightBoss/HudBoss/Tarantula/tarantula.png"))
	boss.set_meta("boss_name", preload("res://Hud/BossHud/HudFightBoss/HudBoss/Tarantula/tarantulaName.png"))

	gs.show_boss_fight_hud(boss)

	cam.limit_bottom = 1240
	cam.limit_right = 3300
		
	player.get_node("Node2D/Sprite").modulate = Color(0.4, 0.4, 0.4)

	await get_tree().process_frame
	await_sound_cinematic()

func on_tarantula_dead(_boss_position):
	player.collect_skills.collect_ramp()


func await_sound_cinematic():
	await get_tree().create_timer(7.0).timeout
	$Node2D/Sound/lvl2.play()
