extends CanvasLayer

# -----------------------------
#            NODES
# -----------------------------
@onready var moko_lives = $MokoLives
@onready var portrait_3_lives = $MokoLives/Portrait3Lives
@onready var portrait_2_lives = $MokoLives/Portrait2lives
@onready var portrait_1_life = $MokoLives/Portrait1Life
@onready var portrait_0_life = $MokoLives/Portrait0Life

@onready var ramp_button = $Gamepad/Ramp
@onready var sprint_button = $Gamepad/Sprint
@onready var coco_button = $Gamepad/Coco
@onready var lance_button = $Gamepad/Spear
@onready var health_button = $Gamepad/Health
@onready var honey_button = $Gamepad/Honey
@onready var bone_button = $Gamepad/Bone
@onready var camouflage_button = $Gamepad/Camouflage
@onready var fire_button = $Gamepad/Fire
@onready var air_button = $Gamepad/Air

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
@onready var fire_buff = $BarSlot/FireBuff
@onready var air_buff = $BarSlot/AirBuff

@onready var banane_cooldown = $Gamepad/Health/coolDownCircle
@onready var honey_cooldown = $Gamepad/Honey/coolDownCircle

@onready var anim_coco = get_node_or_null("Gamepad/Coco/AnimCoco")
@onready var anim_spear = get_node_or_null("Gamepad/Spear/AnimSpear")
@onready var anim_bone = get_node_or_null("Gamepad/Bone/AnimBone")
@onready var anim_potion = get_node_or_null("Gamepad/Health/AnimPotion")
@onready var anim_honey = get_node_or_null("Gamepad/Honey/AnimHoney")
@onready var anim_camouflage = get_node_or_null("Gamepad/Camouflage/AnimCamouflage")
@onready var anim_fire = get_node_or_null("Gamepad/Fire/AnimFire")
@onready var anim_air = get_node_or_null("Gamepad/Air/AnimAir")
@onready var anim_ramp = get_node_or_null("Gamepad/Ramp/AnimRamp")
@onready var anim_sprint = get_node_or_null("Gamepad/Sprint/AnimSprint")


# --- Craft fire_skill ---
@onready var fire_craft_checklist = get_node_or_null("FireCraftChecklist")
@onready var wood_check = get_node_or_null("FireCraftChecklist/WoodRow/Check")
@onready var stone_check = get_node_or_null("FireCraftChecklist/StoneRow/Check")
@onready var recipe_fire_check = get_node_or_null("FireCraftChecklist/RecipeFireRow/Check")
@onready var altar_fire_check = get_node_or_null("FireCraftChecklist/AltarFireRow/Check")
@onready var wood_label_checklist = get_node_or_null("FireCraftChecklist/WoodRow/Label")
@onready var stone_label_checklist = get_node_or_null("FireCraftChecklist/StoneRow/Label")
@onready var recipe_fire_label_checklist = get_node_or_null("FireCraftChecklist/RecipeRow/Label")
@onready var altar_fire_label_checklist = get_node_or_null("FireCraftChecklist/AltarRow/Label")

# --- Craft air skill ---
@onready var air_craft_checklist = get_node_or_null("AirCraftChecklist")
@onready var leaf_check = get_node_or_null("AirCraftChecklist/LeafRow/Check")
@onready var idole_check = get_node_or_null("AirCraftChecklist/IdoleRow/Check")
@onready var recipe_air_check = get_node_or_null("AirCraftChecklist/RecipeAirRow/Check")
@onready var altar_air_check = get_node_or_null("AirCraftChecklist/AltarAirRow/Check")
@onready var leaf_label_checklist = get_node_or_null("AirCraftChecklist/LeafRow/Label")
@onready var idole_label_checklist = get_node_or_null("AirCraftChecklist/IdoleRow/Label")
@onready var recipe_air_label_checklist = get_node_or_null("AirCraftChecklist/RecipeAirRow/Label")
@onready var altar_air_label_checklist = get_node_or_null("AirCraftChecklist/AltarAirRow/Label")


# --- Quête lvl1 graines ---
@onready var lvl1_checklist = get_node_or_null("Lvl1Checklist")
@onready var lvl1_seed_check = get_node_or_null("Lvl1Checklist/SeedRow/Check")
@onready var lvl1_totem_check = get_node_or_null("Lvl1Checklist/TotemRow/Check")
@onready var lvl1_key_check = get_node_or_null("Lvl1Checklist/KeyRow/Check")
# -----------------------------
#            VARS
# -----------------------------
var gs

var banane_cd_left = 0.0
var banane_cd_total = 1.0
var honey_cd_left = 0.0
var honey_cd_total = 1.0

#--- Mode Dirt ---
@export var dirt_spot_scene: PackedScene
@export var dirt_texture: Texture2D
@export var dirt_clean_delay = 15.0
@export var dirt_min_scale = 0.6
@export var dirt_max_scale = 1.2
@export var dirt_min_rotation = -20
@export var dirt_max_rotation = 20

@onready var dirt_layer = $DirtRoot/DirtLayer
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
	fire_button.visible = false
	air_button.visible = false
	sprint_button.visible = false

	if banane_hbox:
		banane_hbox.visible = false
	if honey_hbox:
		honey_hbox.visible = false

	if fire_craft_checklist:
		fire_craft_checklist.visible = false
	
	if air_craft_checklist:
		air_craft_checklist.visible = false
	
	if lvl1_checklist:
		lvl1_checklist.visible = false

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
	set_button_enabled(fire_button, false)
	set_button_enabled(air_button, false)
	
	update_lives_display(gs.lives)
	update_lance_display()
	update_bone_display()
	update_banane_display()
	update_honey_display()
	update_coco_display()
	update_camouflage_display()
	update_fire_display()
	update_air_display()
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

	if gs.fire_buff_unlocked:
		_show_fire()
		update_fire_display()

	if gs.air_buff_unlocked:
		_show_air()
		update_air_display()
	
	if gs.bone_count > 0 or gs.can_fire_bone:
		_show_bone()
		update_bone_display()

	for b in [ramp_button, sprint_button, coco_button, lance_button, health_button, honey_button, bone_button, camouflage_button, fire_button, air_button]:
		b.action = ""

	if break_sprite:
		break_sprite.visible = false

	if breath_progress:
		breath_progress.max_value = 30
		breath_progress.value = 30

	banane_cooldown.visible = false
	honey_cooldown.visible = false

	if bar_slot and bar_slot.has_method("refresh_layout"):
		bar_slot.refresh_layout()

	update_fire_craft_checklist()
	update_air_craft_checklist()
	update_lvl1_checklist()


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

func _show_fire():
	fire_button.visible = true
	update_fire_display()

func _show_air():
	air_button.visible = true
	update_air_display()

# -----------------------------
#        BUFF HUD
# -----------------------------
func _hide_all_buffs():
	if fire_buff and fire_buff.has_method("hide_buff"):
		fire_buff.hide_buff()

	if bar_slot and bar_slot.has_method("hide_buffs"):
		bar_slot.hide_buffs()

# --- Fire ---
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

# --- Air ---
func show_air_buff(duration):
	if air_buff and air_buff.has_method("show_buff"):
		air_buff.show_buff(duration)

	if bar_slot and bar_slot.has_method("show_buffs"):
		bar_slot.show_buffs()

func hide_air_buff():
	if air_buff and air_buff.has_method("hide_buff"):
		air_buff.hide_buff()

	if bar_slot and bar_slot.has_method("hide_buffs"):
		bar_slot.hide_buffs()

func update_air_buff_timer(time_left, duration):
	if air_buff and air_buff.has_method("update_timer"):
		air_buff.update_timer(time_left, duration)


# -----------------------------
#        UPDATE HUD
# -----------------------------
func update_lives_display(lives):
	portrait_3_lives.visible = lives >= 3
	portrait_2_lives.visible = lives == 2
	portrait_1_life.visible = lives <= 1
	portrait_0_life.visible = lives <= 0
	


func set_button_enabled(button, enabled):
	var shape = button.get_node_or_null("CollisionShape2D")
	if shape:
		shape.disabled = not enabled

	if enabled:
		button.modulate = Color(1, 1, 1, 1)
	else:
		button.modulate = Color(1, 1, 1, 0.4)

func update_hud_buttons(can_fire_coco, can_fire_lance, can_heal, can_ramp, can_sprint, can_camouflage, can_fire):
	if coco_button.visible:
		set_button_enabled(coco_button, can_fire_coco)

	if bone_button.visible:
		set_button_enabled(bone_button, gs.bone_count > 0)

	if lance_button.visible:
		set_button_enabled(lance_button, can_fire_lance)

	if camouflage_button.visible:
		set_button_enabled(camouflage_button, can_camouflage)
	
	if fire_button.visible:
		set_button_enabled(fire_button, can_fire)

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

func update_fire_display():
	if not gs.fire_buff_unlocked:
		set_button_enabled(fire_button, false)
		return

	fire_button.visible = true
	set_button_enabled(fire_button, true)

func update_air_display():
	if not gs.air_buff_unlocked:
		set_button_enabled(air_button, false)
		return

	air_button.visible = true
	set_button_enabled(air_button, true)

# ============================================================================
#        BOSS FIGHT HUD
# ============================================================================
func set_gameplay_hud_visible(not_visible):
	$MokoLives.visible = not_visible
	$HBoxContainerSeed.visible = not_visible
	$HBoxContainerBanane.visible = not_visible
	$HBoxContainerHoney.visible = not_visible
	$BarSlot.visible = not_visible
	$HealthBar.visible = not_visible
	$HBoxContainerBanane/TexturePotion.visible = not_visible
	$Gamepad/Menu.visible = not_visible
	$Gamepad/Break.visible = not_visible

	if fire_craft_checklist:
		fire_craft_checklist.visible = is_visible and gs.fire_craft_revealed

	if air_craft_checklist:
		air_craft_checklist.visible = is_visible and gs.air_craft_revealed


# =============================================================================
#              QUETES LVL1 COLLECTE DE GRAINES                         
# ============================================================================
# --- Ultilitaire pour check les objectifs de quete accomplies
func update_check_texture(check_node, is_valid):
	if check_node == null:
		return

	if is_valid:
		check_node.texture = preload("res://Items/CheckBox/valid.png")
	else:
		check_node.texture = preload("res://Items/CheckBox/empty.png")

# --- Lvl1 collecte de graines ---  
func update_lvl1_checklist():
	if lvl1_checklist == null:
		return

	if not gs.lvl1_quest_revealed:
		lvl1_checklist.visible = false
		return

	lvl1_checklist.visible = true

	update_check_texture(lvl1_seed_check, gs.lvl1_seeds_done)
	update_check_texture(lvl1_totem_check, gs.lvl1_totem_done)
	update_check_texture(lvl1_key_check, gs.lvl1_key_done)


func appear_lvl1_quest():
	if lvl1_checklist:
		lvl1_checklist.visible = true

	var anim = get_node_or_null("Lvl1Checklist/AnimationPlayer")
	if anim:
		anim.play("appear_lvl1_quest")
		await anim.animation_finished

	update_lvl1_checklist()


func disappear_lvl1_quest():
	var anim = get_node_or_null("Lvl1Checklist/AnimationPlayer")
	if anim:
		anim.play("disappear_lvl1_quest")


# --- Lvl2 Quête maitrise du feu ---
func update_fire_craft_checklist():
	if fire_craft_checklist == null:
		return

	if not gs.fire_craft_revealed:
		fire_craft_checklist.visible = false
		return

	fire_craft_checklist.visible = true

	update_check_texture(wood_check, gs.wood_collected)
	update_check_texture(stone_check, gs.stone_collected)
	update_check_texture(recipe_fire_check, gs.fire_recipe_unlocked)
	update_check_texture(altar_fire_check, gs.fire_altar_found)

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

# --- Lvl3 Quête maitrise de l'air ---
func update_air_craft_checklist():
	if air_craft_checklist == null:
		return

	if not gs.air_craft_revealed:
		air_craft_checklist.visible = false
		return

	air_craft_checklist.visible = true

	update_check_texture(leaf_check, gs.leaf_collected)
	update_check_texture(idole_check, gs.idole_collected)
	update_check_texture(recipe_air_check, gs.air_recipe_unlocked)
	update_check_texture(altar_air_check, gs.air_altar_found)

func appear_air_craft_quest():
	if air_craft_checklist:
		air_craft_checklist.visible = true

	var anim = get_node_or_null("AirCraftChecklist/AnimationPlayer")
	if anim:
		anim.play("appear_air_craft_quest")
		await anim.animation_finished

	update_air_craft_checklist()

func disappear_air_craft_quest():
	var anim = get_node_or_null("AirCraftChecklist/AnimationPlayer")
	if anim:
		anim.play("disappear_air_craft_quest")

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
#        SALISSURE HUD
# ============================================================================
func spawn_hud_dirt(texture = null):

	# 1. Choix de la texture
	if texture == null:
		texture = dirt_texture

	if texture == null:
		return

	# 2. Création du dirt
	var dirt = dirt_spot_scene.instantiate()
	dirt_layer.add_child(dirt)

	# 3. Récupération tailles
	var screen_size = get_viewport().get_visible_rect().size
	var texture_size = texture.get_size()

	# 4. Découpage écran en 3x3
	var grid_columns = 3
	var grid_rows = 3

	var cell_width = screen_size.x / grid_columns
	var cell_height = screen_size.y / grid_rows

	# 5. Choix d'une case random
	var random_col = randi() % grid_columns
	var random_row = randi() % grid_rows

	# 6. Zone de spawn dans la case
	var min_x = random_col * cell_width
	var max_x = min_x + cell_width - texture_size.x

	var min_y = random_row * cell_height
	var max_y = min_y + cell_height - texture_size.y

	# 7. Position finale random dans la case
	var random_x = randf_range(min_x, max_x)
	var random_y = randf_range(min_y, max_y)

	dirt.position = Vector2(random_x, random_y)

	# 8. Variations visuelles
	var random_scale = randf_range(dirt_min_scale, dirt_max_scale)
	dirt.scale = Vector2(random_scale, random_scale)

	var random_rotation = randf_range(dirt_min_rotation, dirt_max_rotation)
	dirt.rotation_degrees = random_rotation

	# 9. Setup du dirt
	dirt.texture = texture
	dirt.clean_delay = dirt_clean_delay

	# 10. Lancement animation
	dirt.start()


# ============================================================================
#                   APPEAR / ANIM_TO
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

func appear_fire():
	_show_fire()
	update_fire_display()
	if anim_fire:
		anim_fire.stop()
		anim_fire.play("appear_fire")

func appear_air():
	_show_air()
	update_air_display()
	if anim_air:
		anim_air.stop()
		anim_air.play("appear_air")

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
	gs.player.skills_mod.toggle_ramp()

func _on_bone_pressed():
	gs.player.combat_mod.process_bone()

func _on_camouflage_pressed():
	gs.player.skills_mod.use_camouflage()

func _on_break_pressed():
	gs.toggle_pause()

func _on_sprint_pressed():
	gs.player.skills_mod.use_sprint()

func set_pause_visual(paused):
	if break_sprite:
		break_sprite.visible = paused

func _on_fire_pressed():
	gs.player.fire_buff_mod.activate_fire_buff()

func _on_air_pressed():
	gs.player.air_buff_mod.activate_air_buff()

func _on_kick_pressed():
	gs.player.combat_mod.process_kick()
