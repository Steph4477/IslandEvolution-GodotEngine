extends CanvasLayer

# -----------------------------
#            NODES
# -----------------------------
@onready var ramp_button = $Gamepad/Ramp
@onready var sprint_button = $Gamepad/Sprint
@onready var coco_button = $Gamepad/Coco
@onready var lance_button = $Gamepad/Spear
@onready var health_button = $Gamepad/Health
@onready var honey_button = $Gamepad/Honey
@onready var bone_button = $Gamepad/Bone
@onready var camouflage_button = $Gamepad/Camouflage

@onready var pause_button = $Gamepad/Break
@onready var break_sprite = get_node_or_null("BreakSprite")

@onready var lance_label = get_node_or_null("Gamepad/Spear/LanceCountLabel")
@onready var bone_label = get_node_or_null("Gamepad/Bone/BoneCountLabel")

@onready var banane_label = get_node_or_null("Gamepad/Health/BananeCountLabel")
@onready var honey_label = get_node_or_null("Gamepad/Honey/HoneyCountLabel")
@onready var coco_label = get_node_or_null("Gamepad/Coco/CocoCountLabel")
@onready var camouflage_label = get_node_or_null("Gamepad/Camouflage/CamouflageCountLabel")

@onready var banane_hbox = get_node_or_null("HBoxContainerBanane")
@onready var honey_hbox = get_node_or_null("HBoxContainerHoney")
@onready var coco_hbox = get_node_or_null("HbcCoco/HBoxContainerCoco")
@onready var bone_hbox = get_node_or_null("HbcBone/HBoxContainerBone")

@onready var anim = $AnimationPlayer

# -----------------------------
#            VARS
# -----------------------------
var gs
var bone_mode_already_unlocked = false
var honey_mode_already_unlocked = false

# -----------------------------
#            READY
# -----------------------------
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	gs = get_node("/root/GameState")
	gs.hud = self

	# --- Visibilités initiales ---
	ramp_button.visible = false
	sprint_button.visible = false
	honey_button.visible = false
	bone_button.visible = false
	camouflage_button.visible = false
	health_button.visible = true

	if honey_hbox:
		honey_hbox.visible = false
	if banane_hbox:
		banane_hbox.visible = true
	if coco_hbox:
		coco_hbox.visible = true
	if bone_hbox:
		bone_hbox.visible = false

	# --- Désactive les boutons au lancement ---
	set_button_enabled(ramp_button, false)
	set_button_enabled(sprint_button, false)
	set_button_enabled(coco_button, false)
	set_button_enabled(lance_button, false)
	set_button_enabled(health_button, false)
	set_button_enabled(honey_button, false)
	set_button_enabled(bone_button, false)
	set_button_enabled(camouflage_button, false)

	# --- Init affichage ---
	update_lives_display(gs.lives)
	update_lance_display()
	update_bone_display()
	update_banane_display()
	update_honey_display()
	update_coco_display()
	update_camouflage_display()
	update_seed_display(gs.collected_seeds, gs.total_seeds_in_level)

	# --- Restore états persistants ---
	if gs.honey_count > 0:
		honey_mode_already_unlocked = true
		_finalize_switch_to_honey()

	if gs.bone_count > 0:
		bone_mode_already_unlocked = true
		_finalize_switch_to_bone()

	if gs.camouflage_unlocked:
		_finalize_switch_to_camouflage()

	for b in [ramp_button, sprint_button, coco_button, lance_button, health_button, honey_button, bone_button, camouflage_button]:
		if b:
			b.action = ""

	if break_sprite:
		break_sprite.visible = false

# -----------------------------
#        COOLDOWNS
# -----------------------------
func start_banane_cooldown(duration):
	var cd = $HBoxContainerBanane/TexturePotion/coolDownCircle
	cd.value = 100
	cd.show()
	var t = create_tween()
	t.tween_property(cd, "value", 0, duration)
	t.finished.connect(func(): cd.hide())

func start_honey_cooldown(duration):
	var cd = $HBoxContainerHoney/TexturePotion/coolDownCircle
	cd.value = 100
	cd.show()
	var t = create_tween()
	t.tween_property(cd, "value", 0, duration)
	t.finished.connect(func(): cd.hide())

func start_camouflage_cooldown(duration):
	var cd = $Gamepad/Camouflage/coolDownCircle
	cd.value = 100
	cd.show()
	var t = create_tween()
	t.tween_property(cd, "value", 0, duration)
	t.finished.connect(func(): cd.hide())


# -----------------------------
#        UPDATE HUD
# -----------------------------
func update_lives_display(lives):
	var life_sprites = get_node_or_null("HBoxContainerLive")
	var arr = life_sprites.get_children()
	for i in range(arr.size()):
		arr[i].visible = i < lives

func set_button_enabled(button, enabled):
	if button is TouchScreenButton:
		var shape = button.get_node_or_null("CollisionShape2D")
		if shape:
			shape.disabled = not enabled
		if enabled:
			button.modulate = Color(1,1,1,1)
		else:
			button.modulate = Color(1,1,1,0.4)

func update_hud_buttons(can_fire_coco, can_fire_lance, can_heal, can_ramp, can_sprint, can_camouflage):
	set_button_enabled(coco_button, can_fire_coco)

	# --- Lance ou Camouflage selon le mode ---
	if camouflage_button.visible:
		set_button_enabled(camouflage_button, can_camouflage)
		set_button_enabled(lance_button, false)
	else:
		set_button_enabled(lance_button, can_fire_lance)
		set_button_enabled(camouflage_button, false)

	# --- Banane ou Miel selon le mode
	if honey_button.visible:
		set_button_enabled(honey_button, can_heal)
		set_button_enabled(health_button, false)
	else:
		set_button_enabled(health_button, can_heal)
		set_button_enabled(honey_button, false)

	ramp_button.visible = can_ramp
	set_button_enabled(ramp_button, can_ramp)

	sprint_button.visible = can_sprint
	set_button_enabled(sprint_button, can_sprint)

func update_seed_display(collected, total):
	var label = $HBoxContainerSeed/SeedCountLabel
	if total > 0:
		var p = int(round(float(collected) / float(total) * 100))
		label.text = "%d / %d (%d%%)" % [collected, total, p]
	else:
		label.text = "0 / 0 (0%)"

func update_lance_display():
	lance_label.text = str(gs.lance_count)
	set_button_enabled(lance_button, gs.lance_count > 0)

func update_bone_display():
	bone_label.text = str(gs.bone_count)
	set_button_enabled(bone_button, gs.bone_count > 0)

func update_banane_display():
	banane_label.text = str(gs.banane_count)

func update_honey_display():
	honey_label.text = str(gs.honey_count)

func update_coco_display():
	coco_label.text = str(gs.coco_count)
	set_button_enabled(coco_button, gs.coco_count > 0)

func update_camouflage_display():
	camouflage_label.text = str(gs.camouflage_count)

	if not gs.camouflage_unlocked:
		set_button_enabled(camouflage_button, false)
		return

	set_button_enabled(camouflage_button, gs.camouflage_count > 0)


# -----------------------------
#          SWITCHES
# -----------------------------
# Banane -> Honey
func anim_to_honey_mode():
	update_honey_display()

	if honey_mode_already_unlocked:
		_finalize_switch_to_honey()
		return

	honey_mode_already_unlocked = true

	honey_button.visible = true
	honey_hbox.visible = true
	set_button_enabled(honey_button, false)

	anim.play("appear_honey")
	await anim.animation_finished

	_finalize_switch_to_honey()

func _finalize_switch_to_honey():
	health_button.visible = false
	banane_hbox.visible = false
	honey_button.visible = true
	honey_hbox.visible = true
	set_button_enabled(honey_button, gs.honey_count > 0)
	update_honey_display()


# Coco -> Bone
func anim_to_bone_mode():
	update_bone_display()

	if bone_mode_already_unlocked:
		_finalize_switch_to_bone()
		return

	bone_mode_already_unlocked = true
	bone_button.visible = true
	bone_hbox.visible = true

	set_button_enabled(bone_button, false)

	anim.play("bone_appear")
	await anim.animation_finished

	_finalize_switch_to_bone()

func _finalize_switch_to_bone():
	coco_button.visible = false
	coco_hbox.visible = false
	bone_button.visible = true
	bone_hbox.visible = true

	set_button_enabled(bone_button, gs.bone_count > 0)
	update_bone_display()

# Lance -> Cammouflage 
func unlock_camouflage_hud():
	_finalize_switch_to_camouflage()

	if anim.has_animation("appear_camouflage"):
		anim.play("appear_camouflage")
	
	await anim.animation_finished
	
	if anim.has_animation("disappear_spear"):
		anim.play("disappear_spear")

func _finalize_switch_to_camouflage():
	lance_button.visible = false
	set_button_enabled(lance_button, false)

	camouflage_button.visible = true
	update_camouflage_display()

# --------------------------------------
#            DESWITCH
# --------------------------------------
# camouflage -> lance
func switch_back_to_spear():
	# Sécurité
	if not camouflage_button.visible:
		return

	# Anim disparition camouflage
	if anim and anim.has_animation("disappear_camouflage"):
		anim.play("disappear_camouflage")
		await anim.animation_finished

	# Cache camouflage
	camouflage_button.visible = false
	set_button_enabled(camouflage_button, false)

	# Anim apparition lance
	lance_button.visible = true
	if anim and anim.has_animation("appear_spear"):
		anim.play("appear_spear")

	update_lance_display()


# -----------------------------
#           BUTTONS
# -----------------------------
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

func _on_camouflage_pressed():
	gs.player.use_camouflage()

func _on_break_pressed():
	gs.toggle_pause()

func set_pause_visual(paused):
	break_sprite.visible = paused
