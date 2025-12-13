extends CanvasLayer

@onready var ramp_button = $Gamepad/Ramp
@onready var sprint_button = $Gamepad/Sprint
@onready var coco_button = $Gamepad/Coco
@onready var lance_button = $Gamepad/Spear
@onready var health_button = $Gamepad/Health
@onready var honey_button = $Gamepad/Honey
@onready var bone_button = $Gamepad/Bone

@onready var life_sprites = $HBoxContainerLive.get_children()
@onready var pause_button = $Gamepad/Break
@onready var break_sprite = $BreakSprite
@onready var lance_label = $Gamepad/Spear/LanceCountLabel

@onready var coco_hbox = $HbcCoco/HBoxContainerCoco
@onready var bone_hbox = $HbcBone/HBoxContainerBone
@onready var bone_label = $Gamepad/Bone/BoneCountLabel

@onready var banane_label = $Gamepad/Health/BananeCountLabel
@onready var honey_label = $Gamepad/Honey/HoneyCountLabel
@onready var coco_label = $Gamepad/Coco/CocoCountLabel

@onready var banane_hbox = $HBoxContainerBanane
@onready var honey_hbox = $HBoxContainerHoney

@onready var anim = $AnimationPlayer

var gs
var bone_mode_already_unlocked = false
var honey_mode_already_unlocked = false


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	gs = get_node("/root/GameState")
	gs.hud = self

	ramp_button.visible = false
	sprint_button.visible = false

	set_button_enabled(ramp_button, false)
	set_button_enabled(sprint_button, false)
	set_button_enabled(coco_button, false)
	set_button_enabled(lance_button, false)
	set_button_enabled(health_button, false)
	set_button_enabled(honey_button, false)
	set_button_enabled(bone_button, false)

	#  Préparation du mode Honey
	health_button.visible = true
	honey_button.visible = false
	banane_hbox.visible = true
	honey_hbox.visible = false

	# Préparation du mode bone
	if coco_hbox:
		coco_hbox.visible = true
	if bone_hbox:
		bone_hbox.visible = false
	bone_button.visible = false
	
	# Update hud en temps réel
	update_lives_display(gs.lives)
	update_lance_display()
	update_bone_display()
	update_banane_display()
	update_honey_display()
	update_coco_display()
	update_seed_display(gs.collected_seeds, gs.total_seeds_in_level)
	
	if gs.bone_count > 0:
		bone_mode_already_unlocked = true
		_finalize_switch_to_bone()
	
	if gs.honey_count > 0:
		honey_mode_already_unlocked = true
		_finalize_switch_to_honey()
	
	for b in [ramp_button, coco_button, lance_button, health_button, honey_button, bone_button, sprint_button]:
		if b:
			b.action = ""
	
	break_sprite.visible = false

# -----------------------------
#           COOLDOWN 
# -----------------------------

# --- Banane ---
func start_banane_cooldown(duration_sec):
	var cooldown = $HBoxContainerBanane/TexturePotion/coolDownCircle
	cooldown.value = 100
	cooldown.show()
	var tween = create_tween()
	tween.tween_property(cooldown, "value", 0, duration_sec).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func(): cooldown.hide())

# --- Miel ---
func start_honey_cooldown(duration_sec):
	var cooldown = $HBoxContainerHoney/TexturePotion/coolDownCircle
	cooldown.value = 100
	cooldown.show()
	var tween = create_tween()
	tween.tween_property(cooldown, "value", 0, duration_sec).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func(): cooldown.hide())

# -----------------------------------------------------
#                UPDATE HUD 
# -----------------------------------------------------

# --- Vies ---
func update_lives_display(lives):
	life_sprites = $HBoxContainerLive.get_children()
	for i in range(life_sprites.size()):
		life_sprites[i].visible = i < lives

# --- Boutons ---
func set_button_enabled(button, enabled):
	if button is TouchScreenButton:
		var shape = button.get_node_or_null("CollisionShape2D")
		if shape:
			shape.disabled = not enabled

		if enabled:
			button.modulate = Color(1, 1, 1, 1)
		else:
			button.modulate = Color(1, 1, 1, 0.4)

func update_hud_buttons(can_fire_coco, can_fire_lance, can_heal, can_ramp, can_sprint):
	set_button_enabled(coco_button, can_fire_coco)
	set_button_enabled(lance_button, can_fire_lance)

	if honey_button.visible:
		set_button_enabled(honey_button, can_heal)
	else:
		set_button_enabled(health_button, can_heal)

	ramp_button.visible = can_ramp
	set_button_enabled(ramp_button, can_ramp)

	sprint_button.visible = can_sprint
	set_button_enabled(sprint_button, can_sprint)

func set_coco_button_enabled(enabled):
	set_button_enabled(coco_button, enabled)

func set_heal_button_enabled(enabled):
	if honey_button.visible:
		set_button_enabled(honey_button, enabled)
	else:
		set_button_enabled(health_button, enabled)

func set_lance_button_enabled(enabled):
	set_button_enabled(lance_button, enabled)

func set_bone_button_enabled(enabled):
	set_button_enabled(bone_button, enabled)

# --- Compteurs ---
func update_seed_display(collected, total):
	var label = $HBoxContainerSeed/SeedCountLabel
	if total > 0:
		var percent = int(round(float(collected) / float(total) * 100))
		label.text = "%d / %d (%d%%)" % [collected, total, percent]
	else:
		label.text = "0 / 0 (0%)"

func update_lance_display():
	lance_label.text = str(gs.lance_count)
	if gs.lance_count > 0:
		set_lance_button_enabled(true)
	else:
		set_lance_button_enabled(false)

func update_bone_display():
	bone_label.text = str(gs.bone_count)
	if gs.bone_count > 0:
		set_bone_button_enabled(true)
	else:
		set_bone_button_enabled(false)

func update_banane_display():
	banane_label.text = str(gs.banane_count)

func update_honey_display():
	honey_label.text = str(gs.honey_count)

func update_coco_display():
	coco_label.text = str(gs.coco_count)
	if gs.coco_count > 0:
		set_coco_button_enabled(true)
	else:
		set_coco_button_enabled(false)

# -----------------------------
#          SWITCH
# -----------------------------

# --- Banane -> Miel ---
func anim_to_honey_mode():
	update_honey_display()

	if honey_mode_already_unlocked:
		_finalize_switch_to_honey()
		return

	honey_mode_already_unlocked = true

	honey_button.visible = true
	honey_hbox.visible = true

	set_button_enabled(health_button, false)
	set_button_enabled(honey_button, false)

	anim.play("appear_honey")
	await anim.animation_finished

	_finalize_switch_to_honey()

func _finalize_switch_to_honey():
	health_button.visible = false
	banane_hbox.visible = false

	honey_button.visible = true
	honey_hbox.visible = true

	if gs.honey_count > 0:
		set_button_enabled(honey_button, true)
	else:
		set_button_enabled(honey_button, false)

	update_honey_display()

# --- Coco -> Bone ---
func anim_to_bone_mode():
	update_bone_display()

	if bone_mode_already_unlocked:
		_finalize_switch_to_bone()
		return

	bone_mode_already_unlocked = true

	if coco_button:
		coco_button.visible = true
	if coco_hbox:
		coco_hbox.visible = true

	if bone_button:
		bone_button.visible = true
	if bone_hbox:
		bone_hbox.visible = true

	set_coco_button_enabled(false)
	set_bone_button_enabled(false)

	anim.play("bone_appear")
	await anim.animation_finished

	_finalize_switch_to_bone()

func _finalize_switch_to_bone():
	if coco_button:
		coco_button.visible = false
	if coco_hbox:
		coco_hbox.visible = false

	if bone_button:
		bone_button.visible = true
		set_bone_button_enabled(true)

	if bone_hbox:
		bone_hbox.visible = true

	update_bone_display()

# --------------------------------
#           BOUTONS
# --------------------------------
func _on_menu_pressed():
	gs.load_level("res://Levels/Lvl0/lvl_0.tscn")

func _on_hand_pressed():
	gs.player.clac_attack()

func _on_coco_pressed():
	gs.player.shoot_coco()

func _on_health_pressed():
	gs.player.use_heal_item()

func _on_honey_pressed():
	gs.player.use_heal_item()

func _on_spear_pressed():
	gs.player.shoot_lance()

func _on_ramp_pressed():
	gs.player.process_ramp()

func _on_speed_pressed():
	gs.player.process_sprint()

func _on_bone_pressed():
	gs.player.shoot_bone()

func _on_break_pressed():
	gs.toggle_pause()

func set_pause_visual(paused):
	break_sprite.visible = paused
