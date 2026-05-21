extends CanvasLayer

@onready var anim = $Control/Anim

@onready var hp_moko_bar = $Control/HudMoko/HpMokoBar
@onready var hp_boss_bar = $Control/HudBoss/HpBossBar

var player = null
var boss = null


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(player_ref, boss_ref):
	player = player_ref
	boss = boss_ref

	hp_moko_bar.max_value = player.max_pv
	hp_boss_bar.max_value = boss.max_hp

	update_hud()

	anim.play("intro")


func update_hud():
	hp_moko_bar.value = player.pv
	hp_boss_bar.value = boss.hp


func disappear():
	anim.play("disappear")
	await anim.animation_finished
