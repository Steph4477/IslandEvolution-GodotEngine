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

@onready var bar_slot = $BarSlot
@onready var breath_bar = $BarSlot/BreathBar
@onready var breath_progress = $BarSlot/BreathBar/TextureProgressBar
@onready var speed_bar = $BarSlot/SpeedBar
@onready var buff_container = $BarSlot/BuffContainer
@onready var fire_buff = $BarSlot/BuffContainer/FireBuff

@onready var skill_selector = $Gamepad/SkillSelector
@onready var heal_selector = $Gamepad/HealSelector
@onready var throw_selector = $Gamepad/ThrowSelector

@onready var banane_cooldown = $HBoxContainerBanane/TexturePotion/coolDownCircle
@onready var honey_cooldown = $HBoxContainerHoney/TexturePotion/coolDownCircle

@onready var anim_coco = get_node_or_null("Gamepad/Coco/AnimCoco")
@onready var anim_spear = get_node_or_null("Gamepad/Spear/AnimSpear")
@onready var anim_bone = get_node_or_null("Gamepad/Bone/AnimBone")
@onready var anim_potion = get_node_or_null("Gamepad/Health/AnimPotion")
@onready var anim_honey = get_node_or_null("Gamepad/Honey/AnimHoney")
@onready var anim_camouflage = get_node_or_null("Gamepad/Camouflage/AnimCamouflage")
@onready var anim_ramp = get_node_or_null("Gamepad/Ramp/AnimRamp")
@onready var anim_sprint = get_node_or_null("Gamepad/Sprint/AnimSprint")

# --- Craft fire_skill ---
@onready var fire_craft_checklist = get_node_or_null("FireCraftChecklist")

@onready var wood_check = get_node_or_null("FireCraftChecklist/WoodRow/Check")
@onready var stone_check = get_node_or_null("FireCraftChecklist/StoneRow/Check")
@onready var recipe_check = get_node_or_null("FireCraftChecklist/RecipeRow/Check")
@onready var altar_check = get_node_or_null("FireCraftChecklist/AltarRow/Check")

@onready var wood_label_checklist = get_node_or_null("FireCraftChecklist/WoodRow/Label")
@onready var stone_label_checklist = get_node_or_null("FireCraftChecklist/StoneRow/Label")
@onready var recipe_label_checklist = get_node_or_null("FireCraftChecklist/RecipeRow/Label")
@onready var altar_label_checklist = get_node_or_null("FireCraftChecklist/AltarRow/Label")

# -----------------------------
#            VARS
# -----------------------------
var gs

var skill_mode_active = false
var selected_skill = "ramp"

var heal_mode_active = false
var selected_heal = "banane"

var throw_mode_active = false
var selected_throw_weapon = "coco"

var banane_cd_left = 0.0
var banane_cd_total = 1.0
var honey_cd_left = 0.0
var honey_cd_total = 1.0


# -----------------------------
#            READY
# -----------------------------
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	gs = get_node("/root/GameState")
	gs.hud = self

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

	if fire_craft_checklist:
		fire_craft_checklist.visible = false

	hide_breathbar()
	_hide_all_buffs()

	if speed_bar and speed_bar.has_method("hide_bar"):
		speed_bar.hide_bar()

	set_button_enabled(ramp_button, false)
	set_button_enabled(sprint_button, false)
	set_button_enabled(coco_button, false)
	set_button_enabled(lance_button, false)
	set_button_enabled(health_button, false)
	set_button_enabled(honey_button, false)
	set_button_enabled(bone_button, false)
	set_button_enabled(camouflage_button, false)

	update_lives_display(gs.lives)
	update_lance_display()
	update_bone_display()
	update_banane_display()
	update_honey_display()
	update_coco_display()
	update_camouflage_display()
	update_seed_display(gs.collected_seeds, gs.total_seeds_in_level)

	if gs.coco_count > 0 or gs.can_fire_coco:
		_show_coco()
		update_coco_display()

	if gs.banane_count > 0:
		_show_health()
		update_banane_display()

	if gs.honey_count > 0:
		_show_honey()
		update_honey_display()

	if gs.lance_count > 0 or gs.can_fire_lance:
		_show_spear()
		update_lance_display()

	if gs.camouflage_unlocked:
		_show_camouflage()
		update_camouflage_display()

	if gs.bone_count > 0 or gs.can_fire_bone:
		_show_bone()
		update_bone_display()

	for b in [ramp_button, sprint_button, coco_button, lance_button, health_button, honey_button, bone_button, camouflage_button]:
		b.action = ""

	if break_sprite:
		break_sprite.visible = false

	if breath_progress:
		breath_progress.max_value = 30
		breath_progress.value = 30

	skill_selector.visible = false
	heal_selector.visible = false
	throw_selector.visible = false

	banane_cooldown.visible = false
	honey_cooldown.visible = false

	if bar_slot and bar_slot.has_method("refresh_layout"):
		bar_slot.refresh_layout()

	update_fire_craft_checklist()

func _process(delta):
	if banane_cd_left > 0.0:
		banane_cd_left -= delta
		if banane_cd_left < 0.0:
			banane_cd_left = 0.0
		banane_cooldown.value = (banane_cd_left / banane_cd_total) * banane_cooldown.max_value
		if banane_cd_left == 0.0:
			banane_cooldown.visible = false

	if honey_cd_left > 0.0:
		honey_cd_left -= delta
		if honey_cd_left < 0.0:
			honey_cd_left = 0.0
		honey_cooldown.value = (honey_cd_left / honey_cd_total) * honey_cooldown.max_value
		if honey_cd_left == 0.0:
			honey_cooldown.visible = false


# -----------------------------
#        HELPERS VISIBILITÉ
# -----------------------------
func _show_coco():
	coco_button.visible = true
	set_button_enabled(coco_button, gs.coco_count > 0)

func _show_bone():
	bone_button.visible = true
	set_button_enabled(bone_button, gs.bone_count > 0)

func _show_spear():
	lance_button.visible = true
	set_button_enabled(lance_button, gs.lance_count > 0)

func _show_health():
	health_button.visible = true
	if banane_hbox:
		banane_hbox.visible = true

func _show_honey():
	honey_button.visible = true
	if honey_hbox:
		honey_hbox.visible = true
	set_button_enabled(honey_button, gs.honey_count > 0)

func _show_camouflage():
	camouflage_button.visible = true
	update_camouflage_display()


# -----------------------------
#        BUFF HUD
# -----------------------------
func _hide_all_buffs():
	if fire_buff and fire_buff.has_method("hide_buff"):
		fire_buff.hide_buff()

	if buff_container:
		buff_container.visible = false

	if bar_slot and bar_slot.has_method("hide_buffs"):
		bar_slot.hide_buffs()

func show_fire_buff(duration):
	if fire_buff and fire_buff.has_method("show_buff"):
		fire_buff.show_buff(duration)

	if bar_slot and bar_slot.has_method("show_buffs"):
		bar_slot.show_buffs()

func hide_fire_buff():
	if fire_buff and fire_buff.has_method("hide_buff"):
		fire_buff.hide_buff()

	if bar_slot and bar_slot.has_method("hide_buffs"):
		bar_slot.hide_buffs()

func update_fire_buff_timer(time_left, duration):
	if fire_buff and fire_buff.has_method("update_timer"):
		fire_buff.update_timer(time_left, duration)


# -----------------------------
#        SELECTOR HELPERS
# -----------------------------
func _hide_all_selectors():
	skill_selector.visible = false
	heal_selector.visible = false
	throw_selector.visible = false

func _place_selector_on_button(selector, btn):
	var tex = btn.texture_normal
	var tex_size = tex.get_size()

	var local_center = tex_size * 0.5
	var global_center = btn.global_transform * local_center
	selector.global_position = global_center

	var sx = abs(btn.scale.x)
	var sy = abs(btn.scale.y)
	var visual_size = Vector2(tex_size.x * sx, tex_size.y * sy)

	var selector_tex = selector.texture
	var selector_size = selector_tex.get_size()

	var pad = 6.0
	var target_size = visual_size + Vector2(pad * 2.0, pad * 2.0)

	var EXTRA_SCALE = 1.1
	selector.scale = Vector2(
		(target_size.x / selector_size.x) * EXTRA_SCALE,
		(target_size.y / selector_size.y) * EXTRA_SCALE
	)


# -----------------------------
#        MODE SKILL
# -----------------------------
func set_skill_mode(enabled):
	skill_mode_active = enabled

	if not skill_mode_active:
		skill_selector.visible = false
		return

	_hide_all_selectors()
	skill_selector.visible = true
	_update_skill_selector_position()

func set_skill_selected(skill):
	selected_skill = skill
	if skill_mode_active:
		_update_skill_selector_position()

func _update_skill_selector_position():
	_place_selector_on_button(skill_selector, _get_skill_button(selected_skill))

func _get_skill_button(skill):
	if skill == "ramp":
		return ramp_button
	if skill == "sprint":
		return sprint_button
	if skill == "camouflage":
		return camouflage_button
	return ramp_button


# -----------------------------
#        MODE HEAL
# -----------------------------
func show_heal_mode(item):
	heal_mode_active = true
	selected_heal = item

	_hide_all_selectors()
	heal_selector.visible = true
	_update_heal_selector_position()

func hide_heal_mode():
	heal_mode_active = false
	heal_selector.visible = false

func set_heal_selected(item):
	selected_heal = item
	if heal_mode_active:
		_update_heal_selector_position()

func _update_heal_selector_position():
	_place_selector_on_button(heal_selector, _get_heal_button(selected_heal))

func _get_heal_button(item):
	if item == "honey":
		return honey_button
	return health_button


# -----------------------------
#        MODE THROW
# -----------------------------
func show_throw_mode(weapon):
	throw_mode_active = true
	selected_throw_weapon = weapon

	_hide_all_selectors()
	throw_selector.visible = true
	_update_throw_selector_position()

func hide_throw_mode():
	throw_mode_active = false
	throw_selector.visible = false

func set_throw_selected(weapon):
	selected_throw_weapon = weapon
	if throw_mode_active:
		_update_throw_selector_position()

func _update_throw_selector_position():
	_place_selector_on_button(throw_selector, _get_throw_button(selected_throw_weapon))

func _get_throw_button(weapon):
	if weapon == "bone":
		return bone_button
	if weapon == "lance":
		return lance_button
	return coco_button


# -----------------------------
#        UPDATE HUD
# -----------------------------
func update_lives_display(lives):
	var life_sprites = get_node_or_null("HBoxContainerLive")
	if life_sprites == null:
		return
	var arr = life_sprites.get_children()
	for i in range(arr.size()):
		arr[i].visible = i < lives

func set_button_enabled(button, enabled):
	var shape = button.get_node_or_null("CollisionShape2D")
	if shape:
		shape.disabled = not enabled

	if enabled:
		button.modulate = Color(1, 1, 1, 1)
	else:
		button.modulate = Color(1, 1, 1, 0.4)

func update_hud_buttons(can_fire_coco, can_fire_lance, can_heal, can_ramp, can_sprint, can_camouflage):
	if coco_button.visible:
		set_button_enabled(coco_button, can_fire_coco)

	if bone_button.visible:
		set_button_enabled(bone_button, gs.bone_count > 0)

	if lance_button.visible:
		set_button_enabled(lance_button, can_fire_lance)

	if camouflage_button.visible:
		set_button_enabled(camouflage_button, can_camouflage)

	if health_button.visible:
		set_button_enabled(health_button, can_heal)

	if honey_button.visible:
		set_button_enabled(honey_button, can_heal)

	ramp_button.visible = can_ramp
	set_button_enabled(ramp_button, can_ramp)

	sprint_button.visible = can_sprint
	set_button_enabled(sprint_button, can_sprint)

func update_seed_display(collected, total):
	var label = $HBoxContainerSeed/SeedCountLabel
	if total > 0:
		var pcent = int(round(float(collected) / float(total) * 100))
		label.text = "%d / %d (%d%%)" % [collected, total, pcent]
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

# --- Affichage quest craft_fire_skill
func update_fire_craft_checklist():
	if fire_craft_checklist == null:
		return

	if not gs.fire_craft_revealed:
		fire_craft_checklist.visible = false
		return

	fire_craft_checklist.visible = true

	update_check_texture(wood_check, gs.wood_collected)
	update_check_texture(stone_check, gs.stone_collected)
	update_check_texture(recipe_check, gs.fire_recipe_unlocked)
	update_check_texture(altar_check, gs.fire_altar_found)

func update_check_texture(check_node, is_valid):
	if check_node == null:
		return

	if is_valid:
		check_node.texture = preload("res://Items/CheckBox/valid.png")
	else:
		check_node.texture = preload("res://Items/CheckBox/empty.png")

func appear_fire_craft_quest():
	if fire_craft_checklist:
		fire_craft_checklist.visible = true

	var anim = get_node_or_null("FireCraftChecklist/AnimationPlayer")
	if anim:
		anim.play("appear_fire_craft_quest")
		await anim.animation_finished

	update_fire_craft_checklist()

func disappear_fire_craft_quest():
	var anim = get_node_or_null("FireCraftChecklist/AnimationPlayer")
	if anim:
		anim.play("disappear_fire_craft_quest")
		print("play disappear_quest_craft")

# -----------------------------
#        COOLDOWN API
# -----------------------------
func start_banane_cooldown(duration):
	banane_cd_total = duration
	banane_cd_left = duration
	banane_cooldown.visible = true
	banane_cooldown.value = banane_cooldown.max_value

func start_honey_cooldown(duration):
	honey_cd_total = duration
	honey_cd_left = duration
	honey_cooldown.visible = true
	honey_cooldown.value = honey_cooldown.max_value


# --- Respiration sous l'eau ---
func show_breathbar():
	if breath_bar and breath_bar.has_method("show_bar"):
		breath_bar.show_bar()

	if bar_slot and bar_slot.has_method("show_breath"):
		bar_slot.show_breath()

func hide_breathbar():
	if breath_bar and breath_bar.has_method("hide_bar"):
		breath_bar.hide_bar()

	if bar_slot and bar_slot.has_method("hide_breath"):
		bar_slot.hide_breath()

func start_breath(max_value):
	if breath_progress:
		breath_progress.max_value = max_value
		breath_progress.value = max_value

func update_breath(current, max_value):
	if breath_progress:
		breath_progress.max_value = max_value
		breath_progress.value = clamp(current, 0, max_value)

func stop_breath():
	hide_breathbar()


# ============================================================================
#        RETROCOMPAT : APPEAR / ANIM_TO
# ============================================================================
func appear_coco():
	_show_coco()
	update_coco_display()
	if anim_coco:
		anim_coco.stop()
		anim_coco.play("appear_coco")

func appear_bone():
	_show_bone()
	update_bone_display()
	if anim_bone:
		anim_bone.stop()
		anim_bone.play("appear_bone")

func appear_spear():
	_show_spear()
	update_lance_display()
	if anim_spear:
		anim_spear.stop()
		anim_spear.play("appear_spear")

func anim_to_coco_mode():
	_show_coco()
	update_coco_display()
	if anim_coco:
		anim_coco.stop()
		anim_coco.play("anim_to_coco_mode")

func anim_to_bone_mode():
	_show_bone()
	update_bone_display()
	if anim_bone:
		anim_bone.stop()
		anim_bone.play("anim_to_bone_mode")

func anim_to_spear_mode():
	_show_spear()
	update_lance_display()
	if anim_spear:
		anim_spear.stop()
		anim_spear.play("anim_to_spear_mode")

func appear_health():
	_show_health()
	update_banane_display()
	if anim_potion:
		anim_potion.stop()
		anim_potion.play("appear_health")

func appear_honey():
	_show_honey()
	update_honey_display()
	if anim_honey:
		anim_honey.stop()
		anim_honey.play("appear_honey")

func appear_ramp():
	ramp_button.visible = true
	set_button_enabled(ramp_button, true)
	if anim_ramp:
		anim_ramp.stop()
		anim_ramp.play("appear_ramp")

func appear_sprint():
	sprint_button.visible = true
	set_button_enabled(sprint_button, true)
	if anim_sprint:
		anim_sprint.stop()
		anim_sprint.play("appear_sprint")

func appear_camouflage():
	_show_camouflage()
	update_camouflage_display()
	if anim_camouflage:
		anim_camouflage.stop()
		anim_camouflage.play("appear_camouflage")

func anim_to_health_mode():
	appear_health()

func anim_to_honey_mode():
	appear_honey()

func unlock_camouflage_hud():
	appear_camouflage()


#---------------------------------------
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

func _on_bone_pressed():
	gs.player.combat_mod.process_bone()

func _on_camouflage_pressed():
	gs.player.skills_mod.process_camouflage()

func _on_break_pressed():
	gs.toggle_pause()

func _on_sprint_pressed():
	gs.player.skills_mod.use_sprint()

func set_pause_visual(paused):
	if break_sprite:
		break_sprite.visible = paused
