extends CanvasLayer

@onready var anim = $Control/Anim

@onready var hp_moko_bar = $Control/HudMoko/HpMokoBar
@onready var hp_moko_label = $Control/HudMoko/HpMokoLabel

@onready var hp_boss_bar = $Control/HudBoss/HpBossBar
@onready var hp_boss_label = $Control/HudBoss/HpBossLabel
@onready var boss_portrait = $Control/HudBoss/BossPortrait
@onready var boss_name = $Control/HudBoss/BossName

var player = null
var boss = null


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(player_ref, boss_ref):
	player = player_ref
	boss = boss_ref

	hp_moko_bar.max_value = player.max_pv
	hp_moko_bar.value = player.pv

	hp_boss_bar.max_value = boss.max_hp
	hp_boss_bar.value = boss.hp

	if boss.has_meta("boss_portrait"):
		boss_portrait.texture = boss.get_meta("boss_portrait")

	if boss.has_meta("boss_name"):
		boss_name.texture = boss.get_meta("boss_name")

	update_hud()

	anim.play("intro")


func update_hud():
	hp_moko_bar.max_value = player.max_pv
	hp_moko_bar.value = player.pv
	hp_moko_label.text = str(int(player.pv)) + " / " + str(int(player.max_pv))

	if player.pv > player.max_pv * 0.5:
		hp_moko_label.add_theme_color_override("font_color", Color.BLACK)
	else:
		hp_moko_label.add_theme_color_override("font_color", Color.WHITE)

	hp_boss_bar.max_value = boss.max_hp
	hp_boss_bar.value = boss.hp
	hp_boss_label.text = str(int(boss.hp)) + " / " + str(int(boss.max_hp))

	if boss.hp > boss.max_hp * 0.5:
		hp_boss_label.add_theme_color_override("font_color", Color.BLACK)
	else:
		hp_boss_label.add_theme_color_override("font_color", Color.WHITE)


func disappear():
	anim.play("disappear")
	await anim.animation_finished
