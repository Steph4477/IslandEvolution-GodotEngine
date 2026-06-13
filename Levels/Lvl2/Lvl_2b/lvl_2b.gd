extends Node2D

@export var dialogue_scene = preload("res://Interface/Dialogue/pyg_dialogue.tscn")
@onready var boss = $Tarantula
@onready var loots = $Loots

var cam
var player

func _ready():
	$Node2D/Sound/lvl2.play()
	
	loots.visible = false
	
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

	await_sound_cinematic()

func on_tarantula_dead(_boss_position):
	await get_tree().process_frame

	if player:
		player.disable_controls()

	cam.top_level = true
	cam.global_position = player.global_position

	await focus_camera_on_node("Loots")

	loots.visible = true

	if loots.has_node("AnimationPlayer"):
		loots.get_node("AnimationPlayer").play("appear")

	await get_tree().create_timer(1.5).timeout

	await return_camera_to_player()

	if player:
		player.enable_controls()

# === FOCUS CAMÉRA GÉNÉRIQUE ===
func focus_camera_on_node(node_name):
	var target = get_node_or_null(node_name)
	if not target:
		return

	var tween = create_tween()
	tween.tween_property(cam, "global_position", target.global_position, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	await get_tree().create_timer(0.6).timeout


# === RETOUR CAMÉRA VERS MOKO ===
func return_camera_to_player():
	var tween = create_tween()
	tween.tween_property(cam, "global_position", player.global_position, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	cam.top_level = false
	cam.position = Vector2.ZERO

func await_sound_cinematic():
	await get_tree().create_timer(5).timeout
	$Node2D/Sound/lvl2.play()
