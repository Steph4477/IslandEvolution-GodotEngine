extends CanvasLayer

@onready var hud_moko = $Control/HudMoko
@onready var hud_boss = $Control/HudBoss
@onready var versus = $Control/Versus
@onready var anim = $Control/Anim

@onready var hp_moko_full = $Control/HudMoko/HpMokoFull
@onready var hp_boss_full = $Control/HudBoss/HpBossFull

var player = null
var boss = null


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(player_ref, boss_ref):
	player = player_ref
	boss = boss_ref

	if player != null:
		hp_moko_full.max_value = player.max_pv
		hp_moko_full.value = player.pv

	if boss != null:
		hp_boss_full.max_value = boss.max_hp
		hp_boss_full.value = boss.hp

	if anim:
		anim.play("intro")


func update_hud():
	update_moko_life()
	update_boss_life()


func update_moko_life():
	if player == null:
		return

	hp_moko_full.max_value = player.max_pv
	hp_moko_full.value = player.pv


func update_boss_life():
	if boss == null:
		return

	hp_boss_full.max_value = boss.max_hp
	hp_boss_full.value = boss.hp


func disappear():
	if anim:
		anim.play("disappear")
		await anim.animation_finished
