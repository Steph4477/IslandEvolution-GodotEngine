extends CanvasLayer

@onready var ramp_button = $Gamepad/Ramp
@onready var coco_button = $Gamepad/Coco
@onready var lance_button = $Gamepad/Spear
@onready var health_button = $Gamepad/Health
@onready var bone_button = $Gamepad/Bone

@onready var life_sprites = $HBoxContainerLive.get_children()
@onready var pause_button = $Gamepad/Break   # bouton pause (TouchScreenButton)
@onready var break_sprite = $BreakSprite
@onready var lance_label = $HBoxContainerLance/LanceCountLabel

@onready var coco_hbox = $HbcCoco/HBoxContainerCoco
@onready var bone_hbox = $HbcBone/HBoxContainerBone
@onready var bone_label = $HbcBone/HBoxContainerBone/BoneCountLabel

@onready var anim = $AnimationPlayer

var gs

func _ready():
	# Le HUD doit continuer à recevoir les inputs même quand le jeu est en pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	gs = get_node("/root/GameState")
	
	# Boutons grisés au démarrage (le Moko les activera quand il débloque les items)
	set_button_enabled(ramp_button, false)
	set_button_enabled(coco_button, false)
	set_button_enabled(lance_button, false)
	set_button_enabled(health_button, false)
	set_button_enabled(bone_button, false)
	
	# État initial : on affiche les cocos, pas les bones
	if coco_hbox:
		coco_hbox.visible = true
	if bone_hbox:
		bone_hbox.visible = false
	if bone_button:
		bone_button.visible = false
	
	gs.hud = self
	update_lives_display(gs.lives)
	update_lance_display()
	update_bone_display()
	
	# Neutralise toutes actions d'input des boutons HUD au lancement
	for b in [ramp_button, coco_button, lance_button, health_button, bone_button]:
		if b:
			b.action = "" 
	 
	break_sprite.visible = false

func update_lives_display(lives):
	life_sprites = $HBoxContainerLive.get_children()
	for i in range(life_sprites.size()):
		life_sprites[i].visible = i < lives

func start_banane_cooldown(duration_sec):
	var cooldown = $HBoxContainerBanane/Texture/coolDownCircle
	cooldown.value = 100
	cooldown.show()
	var tween = create_tween()
	tween.tween_property(cooldown, "value", 0, duration_sec).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func(): cooldown.hide())

func set_button_enabled(button, enabled):
	if button is TouchScreenButton:
		var shape = button.get_node_or_null("CollisionShape2D")
		if shape:
			shape.disabled = not enabled
		if enabled:
			button.modulate = Color(1, 1, 1, 1)
		else:
			button.modulate = Color(1, 1, 1, 0.4)

func update_hud_buttons(can_fire_coco, can_fire_lance, can_heal, can_ramp):
	set_button_enabled(coco_button, can_fire_coco)
	set_button_enabled(lance_button, can_fire_lance)
	set_button_enabled(health_button, can_heal)
	set_button_enabled(ramp_button, can_ramp)

func set_coco_button_enabled(enabled):
	set_button_enabled(coco_button, enabled)

func set_heal_button_enabled(enabled):
	set_button_enabled(health_button, enabled)

func set_lance_button_enabled(enabled):
	set_button_enabled(lance_button, enabled)

func set_bone_button_enabled(enabled):
	set_button_enabled(bone_button, enabled)

func update_seed_display(collected, total):
	var label = $HBoxContainerSeed/SeedCountLabel
	if total > 0:
		var percent = int(round(float(collected) / float(total) * 100))
		label.text = "%d / %d (%d%%)" % [collected, total, percent]
	else:
		label.text = "0 / 0 (0%)"

func update_lance_display():
	if lance_label and gs:
		lance_label.text = "x " + str(gs.lance_count)
	
	# Active / désactive le bouton en fonction du stock
	if gs and gs.lance_count > 0:
		set_lance_button_enabled(true)
	else:
		set_lance_button_enabled(false)

func update_bone_display():
	if not gs:
		return
	
	if bone_label:
		bone_label.text = "x " + str(gs.bone_count)
	
	# active/désactive le bouton bone
	if gs.bone_count > 0:
		set_bone_button_enabled(true)
	else:
		set_bone_button_enabled(false)
	
# ---------------------------------------------------------
#  SWITCH COCO -> BONE (appelé quand Moko loot un bone)
# ---------------------------------------------------------
func anim_to_bone_mode():
	update_bone_display()
	
	# Prépare l’anim : les deux doivent être visibles
	if coco_button:
		coco_button.visible = true
	if coco_hbox:
		coco_hbox.visible = true
	
	if bone_button:
		bone_button.visible = true
	if bone_hbox:
		bone_hbox.visible = true
	
	# Inactive les deux boutons pendant l'anim
	set_coco_button_enabled(false)
	set_bone_button_enabled(false)
	
	# Lance l'animation
	if anim:
		anim.play("bone_appear")
		await anim.animation_finished
	
	# Quand l'anim est terminée, on fait le vrai switch
	_finalize_switch_to_bone()

func _finalize_switch_to_bone():
	# Cache coco
	if coco_button:
		coco_button.visible = false
	if coco_hbox:
		coco_hbox.visible = false
	
	# Affiche bone
	if bone_button:
		bone_button.visible = true
		set_bone_button_enabled(true)
	
	if bone_hbox:
		bone_hbox.visible = true
	
	update_bone_display()

# --- Boutons ---
func _on_menu_pressed():
	gs.load_level("res://Levels/Lvl0/lvl_0.tscn")

func _on_hand_pressed():
	gs.player.clac_attack()

func _on_coco_pressed():
	gs.player.shoot_coco()

func _on_health_pressed():
	gs.player.use_banane()

func _on_spear_pressed():
	gs.player.shoot_lance()

func _on_ramp_pressed():
	gs.player.process_ramp()

func _on_bone_pressed():
	if gs and gs.player:
		gs.player.shoot_bone() 

# --- Bouton Pause ---
func _on_break_pressed():
	gs.toggle_pause()

# --- Appelé par GameState -> Affichage de l'ecran de pause par dessus  ---
func set_pause_visual(paused):
	break_sprite.visible = paused
