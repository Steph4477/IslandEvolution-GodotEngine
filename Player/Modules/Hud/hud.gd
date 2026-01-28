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

@onready var anim = $AnimationPlayer

@onready var breath_bar = get_node_or_null("BreathBar")
@onready var breath_progress = get_node_or_null("BreathBar/TextureProgressBar")

# --- UI mode jet ---
@onready var throw_selector = get_node_or_null("Gamepad/ThrowSelector")
@onready var throw_group_flash = get_node_or_null("Gamepad/ThrowGroupFlash")

# -----------------------------
#            VARS
# -----------------------------
var gs
var bone_mode_already_unlocked = false
var honey_mode_already_unlocked = false

var throw_mode_active = false
var selected_throw_weapon = "coco"

# -----------------------------
#            READY
# -----------------------------
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	gs = get_node("/root/GameState")
	gs.hud = self

	# --- Visibilités initiales ---
	coco_button.visible = false
	bone_button.visible = false
	lance_button.visible = false
	camouflage_button.visible = false
	health_button.visible = false
	honey_button.visible = false
	ramp_button.visible = false
	sprint_button.visible = false

	if banane_hbox:
		banane_hbox.visible = false
	if honey_hbox:
		honey_hbox.visible = false

	hide_breathbar()

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
	if gs.coco_count > 0:
		_finalize_appear_coco()

	if gs.banane_count > 0:
		_finalize_appear_health()

	if gs.honey_count > 0:
		honey_mode_already_unlocked = true
		_finalize_appear_honey()

	if gs.lance_count > 0:
		_finalize_appear_spear()

	if gs.camouflage_unlocked:
		_finalize_appear_camouflage()

	if gs.bone_count > 0:
		bone_mode_already_unlocked = true
		_finalize_appear_bone()

	for b in [ramp_button, sprint_button, coco_button, lance_button, health_button, honey_button, bone_button, camouflage_button]:
		if b:
			b.action = ""

	if break_sprite:
		break_sprite.visible = false

	if breath_bar:
		breath_bar.visible = false

	if breath_progress:
		breath_progress.max_value = 30
		breath_progress.value = 30

	if throw_selector:
		throw_selector.visible = false
	if throw_group_flash:
		throw_group_flash.visible = false


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
#        MODE JET HUD
# -----------------------------
func show_throw_mode(weapon):
	throw_mode_active = true
	selected_throw_weapon = weapon

	if throw_selector == null:
		return

	throw_selector.visible = true
	_update_throw_selector_position()


func hide_throw_mode():
	throw_mode_active = false

	if throw_selector:
		throw_selector.visible = false

	if throw_group_flash:
		throw_group_flash.visible = false


func flash_throw_group():
	if throw_group_flash == null:
		return

	_update_throw_group_flash_rect()
	throw_group_flash.visible = true

	await get_tree().create_timer(1.0).timeout
	throw_group_flash.visible = false


func _update_throw_selector_position():
	if throw_selector == null:
		return

	var btn = _get_throw_button(selected_throw_weapon)
	if btn == null:
		return

	var tex = btn.texture_normal
	if tex == null:
		return

	# Centre réel du bouton
	var tex_size = tex.get_size()
	var local_center = tex_size * 0.5
	var global_center = btn.global_transform * local_center
	throw_selector.global_position = global_center

	# --- Scale du carré bleu ---
	var selector_tex = throw_selector.texture
	if selector_tex:
		var selector_size = selector_tex.get_size()

		var pad = 6.0
		var target_size = tex_size + Vector2(pad * 2.0, pad * 2.0)

		var EXTRA_SCALE = 1.1  # 

		throw_selector.scale = Vector2(
			(target_size.x / selector_size.x) * EXTRA_SCALE,
			(target_size.y / selector_size.y) * EXTRA_SCALE
		)


func _update_throw_group_flash_rect():
	if throw_group_flash == null:
		return

	var group = $Gamepad
	var r = group.get_global_rect()

	var pad = 10.0
	throw_group_flash.global_position = Vector2(r.position.x - pad, r.position.y - pad)
	throw_group_flash.size = Vector2(r.size.x + pad * 2.0, r.size.y + pad * 2.0)


func _get_throw_button(weapon):
	if weapon == "coco":
		return coco_button
	if weapon == "bone":
		return bone_button
	return lance_button


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
	# Coco
	if coco_button.visible:
		set_button_enabled(coco_button, can_fire_coco)

	# Bone
	if bone_button.visible:
		set_button_enabled(bone_button, gs.bone_count > 0)

	# Lance
	if lance_button.visible:
		set_button_enabled(lance_button, can_fire_lance)

	# Camouflage
	if camouflage_button.visible:
		set_button_enabled(camouflage_button, can_camouflage)

	# Banane
	if health_button.visible:
		set_button_enabled(health_button, can_heal)

	# Honey
	if honey_button.visible:
		set_button_enabled(honey_button, can_heal)

	# Ramp / Sprint
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
	if lance_label:
		lance_label.text = str(gs.lance_count)
	if lance_button.visible:
		set_button_enabled(lance_button, gs.lance_count > 0)

func update_bone_display():
	if bone_label:
		bone_label.text = str(gs.bone_count)
	if bone_button.visible:
		set_button_enabled(bone_button, gs.bone_count > 0)

func update_banane_display():
	if banane_label:
		banane_label.text = str(gs.banane_count)

func update_honey_display():
	if honey_label:
		honey_label.text = str(gs.honey_count)

func update_coco_display():
	if coco_label:
		coco_label.text = str(gs.coco_count)
	if coco_button.visible:
		set_button_enabled(coco_button, gs.coco_count > 0)

func update_camouflage_display():
	if camouflage_label:
		camouflage_label.text = str(gs.camouflage_count)

	if not gs.camouflage_unlocked:
		set_button_enabled(camouflage_button, false)
		return

	if camouflage_button.visible:
		set_button_enabled(camouflage_button, gs.camouflage_count > 0)


# --- Réspiration sous l'eau ---
func show_breathbar():
	breath_bar.visible = true

func hide_breathbar():
	breath_bar.visible = false

func start_breath(max_value):
	show_breathbar()
	breath_progress.max_value = max_value
	breath_progress.value = max_value

func update_breath(current, max_value):
	show_breathbar()
	breath_progress.max_value = max_value
	breath_progress.value = clamp(current, 0, max_value)

func stop_breath():
	breath_bar.visible = false


# -----------------------------
#          APPEARS (PERSISTANTS)
# -----------------------------
func anim_to_coco_mode():
	update_coco_display()

	if coco_button.visible:
		_finalize_appear_coco()
		return

	coco_button.visible = true
	set_button_enabled(coco_button, false)

	if anim and anim.has_animation("appear_coco"):
		anim.play("appear_coco")
		await anim.animation_finished

	_finalize_appear_coco()

func _finalize_appear_coco():
	coco_button.visible = true
	set_button_enabled(coco_button, gs.coco_count > 0)
	update_coco_display()

func anim_to_spear_mode():
	update_lance_display()

	if lance_button.visible:
		_finalize_appear_spear()
		return

	lance_button.visible = true
	set_button_enabled(lance_button, false)

	if anim and anim.has_animation("appear_spear"):
		anim.play("appear_spear")
		await anim.animation_finished

	_finalize_appear_spear()

func _finalize_appear_spear():
	lance_button.visible = true
	set_button_enabled(lance_button, gs.lance_count > 0)
	update_lance_display()

func anim_to_health_mode():
	update_banane_display()

	if health_button.visible:
		_finalize_appear_health()
		return

	health_button.visible = true
	if banane_hbox:
		banane_hbox.visible = true

	set_button_enabled(health_button, false)

	if anim and anim.has_animation("appear_health"):
		anim.play("appear_health")
		await anim.animation_finished

	_finalize_appear_health()

func _finalize_appear_health():
	health_button.visible = true
	if banane_hbox:
		banane_hbox.visible = true
	update_banane_display()

func anim_to_honey_mode():
	update_honey_display()

	if honey_mode_already_unlocked:
		_finalize_appear_honey()
		return

	honey_mode_already_unlocked = true

	honey_button.visible = true
	if honey_hbox:
		honey_hbox.visible = true
	set_button_enabled(honey_button, false)

	if anim and anim.has_animation("appear_honey"):
		anim.play("appear_honey")
		await anim.animation_finished

	_finalize_appear_honey()

func _finalize_appear_honey():
	honey_button.visible = true
	if honey_hbox:
		honey_hbox.visible = true
	set_button_enabled(honey_button, gs.honey_count > 0)
	update_honey_display()

func anim_to_bone_mode():
	update_bone_display()

	if bone_mode_already_unlocked:
		_finalize_switch_to_bone()
		return

	bone_mode_already_unlocked = true
	bone_button.visible = true

	set_button_enabled(bone_button, false)

	anim.play("bone_appear")
	await anim.animation_finished

	_finalize_switch_to_bone()

func _finalize_switch_to_bone():
	coco_button.visible = true
	bone_button.visible = true

	set_button_enabled(bone_button, gs.bone_count > 0)
	update_bone_display()
	update_coco_display()

func _finalize_appear_bone():
	bone_button.visible = true
	set_button_enabled(bone_button, gs.bone_count > 0)
	update_bone_display()

func unlock_camouflage_hud():
	_finalize_appear_camouflage()

	if anim and anim.has_animation("appear_camouflage"):
		anim.play("appear_camouflage")

func _finalize_appear_camouflage():
	camouflage_button.visible = true
	update_camouflage_display()


# --------------------------------------
#            BUTTONS
# --------------------------------------
func _on_menu_pressed():
	gs.load_level("res://Levels/Lvl0/lvl_0.tscn")

func _on_hand_pressed():
	gs.player.combat_mod.attack()

func _on_coco_pressed():
	gs.player.combat_mod.shoot_coco()

func _on_health_pressed():
	gs.player.heal_mod.use_heal_item()

func _on_honey_pressed():
	gs.player.heal_mod.use_heal_item()

func _on_spear_pressed():
	gs.player.combat_mod.shoot_lance()

func _on_ramp_pressed():
	gs.player.skills_mod.process_ramp()

func _on_speed_pressed():
	gs.player.movement_mod.process_sprint()

func _on_bone_pressed():
	gs.player.combat_mod.process_bone()

func _on_camouflage_pressed():
	gs.player.skills_mod.process_camouflage()

func _on_break_pressed():
	gs.toggle_pause()

func _on_sprint_pressed():
	gs.player.skills_mod.use_sprint()

func set_pause_visual(paused):
	break_sprite.visible = paused
