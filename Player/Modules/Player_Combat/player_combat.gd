extends Node

var p
var firing_locked = false

func setup(player):
	p = player

# ============================================================================
#                                 PROCESS
# ============================================================================
func process():
	shoot()
	clac()

# ============================================================================
#                                 SHOOT
# ============================================================================
func shoot():
	# IMPORTANT : si un mode HUD est actif, SPACE sert au mode, pas au tir combat
	if p.throw_mode or p.heal_mode or p.skill_mode:
		return

	# lock simple pour éviter multi-await en parallèle
	if firing_locked:
		return

	# Coco (shoot)
	if Input.is_action_just_pressed(p.INPUT["fire"]) and p.can_fire_coco:
		firing_locked = true
		await coco()
		firing_locked = false
		return

	# Bone (shoot)
	if Input.is_action_pressed(p.INPUT["fire"]) and p.can_fire_bone:
		firing_locked = true
		await bone()
		firing_locked = false
		return

	# Lance (shoot_spear)
	if not p.can_camouflage and Input.is_action_pressed(p.INPUT["fire"]) and p.can_fire_lance:
		firing_locked = true
		await lance()
		firing_locked = false
		return

func coco():
	if p.is_swimming or p.is_swimming_under_water or p.is_ramping or p.is_hanging or p.is_on_liana or p.is_camouflaged:
		return

	p.coco_count = p.game_state.coco_count
	p.can_fire_coco = p.game_state.can_fire_coco

	if not p.can_fire_coco:
		return
	if p.coco_count <= 0:
		return

	p.animation_locked = true

	if p.is_on_floor():
		p.anim.play("shoot")
	else:
		p.anim.play("jump_shoot")

	await p.anim.animation_finished

	var scene = p.spell_coco
	if p.game_state.fire_buff_unlocked and p.fire_buff_active:
		scene = p.spell_coco_fire

	var spell = scene.instantiate()
	spell.z_index = 30 
	var dir = 1
	if p.sprite.scale.x < 0:
		dir = -1

	spell.start(p.get_node("ShootPoint").global_position, dir)
	p.get_tree().current_scene.add_child(spell)

	p.coco_count -= 1
	p.can_fire_coco = p.coco_count > 0

	p.game_state.coco_count = p.coco_count
	p.game_state.can_fire_coco = p.can_fire_coco

	p.hud_mod.update_coco_display()

	p.animation_locked = false
	p.hud_mod.refresh_hud_buttons()
	await p.get_tree().create_timer(p.rate_of_fire).timeout

func bone():
	if p.is_swimming or p.is_swimming_under_water or p.is_ramping or p.is_hanging or p.is_on_liana or p.is_camouflaged:
		return

	p.bone_count = p.game_state.bone_count
	p.can_fire_bone = p.game_state.can_fire_bone

	if not p.can_fire_bone:
		return
	if p.bone_count <= 0:
		return

	p.bone_count -= 1
	p.can_fire_bone = p.bone_count > 0

	p.game_state.bone_count = p.bone_count
	p.game_state.can_fire_bone = p.can_fire_bone

	p.hud_mod.update_bone_display()

	p.animation_locked = true

	if p.is_on_floor():
		p.anim.play("shoot")
	else:
		p.anim.play("jump_shoot")

	await p.anim.animation_finished

	var scene = p.spell_bone
	if p.game_state.fire_buff_unlocked and p.fire_buff_active:
		scene = p.spell_bone_fire

	var spell = scene.instantiate()
	spell.z_index = 80 
	var dir = 1
	if p.sprite.scale.x < 0:
		dir = -1
	spell.start(p.get_node("ShootPoint").global_position, dir)
	p.get_tree().current_scene.add_child(spell)

	p.animation_locked = false
	p.hud_mod.refresh_hud_buttons()
	await p.get_tree().create_timer(p.rate_of_fire).timeout

func lance():
	if p.can_camouflage:
		return

	if p.is_swimming or p.is_swimming_under_water or p.is_ramping or p.is_hanging or p.is_on_liana or p.is_camouflaged:
		return

	p.lance_count = p.game_state.lance_count
	p.can_fire_lance = p.game_state.can_fire_lance

	if not p.can_fire_lance:
		return
	if p.lance_count <= 0:
		return

	p.lance_count -= 1
	p.can_fire_lance = p.lance_count > 0

	p.game_state.lance_count = p.lance_count
	p.game_state.can_fire_lance = p.can_fire_lance

	p.hud_mod.update_lance_display()

	p.animation_locked = true

	if p.is_on_floor():
		p.anim.play("shoot")
	else:
		p.anim.play("jump_shoot")

	await p.anim.animation_finished

	var scene = p.spell_lance
	if p.game_state.fire_buff_unlocked and p.fire_buff_active:
		scene = p.spell_lance_fire

	var spell = scene.instantiate()
	var dir = 1
	if p.sprite.scale.x < 0:
		dir = -1
	spell.start(p.get_node("ShootPoint").global_position, dir)
	p.get_tree().current_scene.add_child(spell)

	p.animation_locked = false
	p.hud_mod.refresh_hud_buttons()
	await p.get_tree().create_timer(p.rate_of_fire).timeout

# ============================================================================
#                           CLAC / HEADBUTT
# ============================================================================
func clac():
	if not Input.is_action_just_pressed(p.INPUT["clac"]):
		return

	if p.is_swimming_under_water:
		await headbutt()
		return

	await attack()
		
func headbutt():
	if not p.is_swimming_under_water:
		return

	if p.is_dead:
		return

	if p.is_attacking or p.is_headbutting:
		return

	if not p.can_headbutt:
		return

	p.can_headbutt = false
	p.is_attacking = true
	p.is_headbutting = true

	p.get_node("HeadbuttArea").monitoring = true

	var dir = 1
	if p.sprite.scale.x < 0:
		dir = -1

	var elapsed = 0.0

	while elapsed < p.headbutt_duration:
		p.velocity.x = dir * p.headbutt_speed
		p.velocity.y = 0

		if p.anim.current_animation != "headbutt_swim":
			p.anim.play("headbutt_swim")

		await p.get_tree().physics_frame
		elapsed += p.get_physics_process_delta_time()

	p.get_node("HeadbuttArea").monitoring = false
	p.velocity.x = 0
	p.velocity.y = 0
	p.is_headbutting = false
	p.is_attacking = false

	await p.get_tree().create_timer(p.headbutt_cooldown).timeout
	p.can_headbutt = true

func attack():
	if not p.is_on_floor():
		return
	if p.is_attacking or p.is_dead:
		return

	p.is_attacking = true
	p.animation_locked = true

	p.anim.play("clac")
	p.get_node("ClacArea").monitoring = true

	await p.anim.animation_finished

	p.get_node("ClacArea").monitoring = false
	p.is_attacking = false
	p.animation_locked = false

# ============================================================================
#                         ALIAS API (HUD)
# ============================================================================
func shoot_coco():
	if firing_locked:
		return

	firing_locked = true
	await coco()
	firing_locked = false

func process_bone():
	if firing_locked:
		return

	firing_locked = true
	await bone()
	firing_locked = false

func shoot_lance():
	if firing_locked:
		return

	firing_locked = true
	await lance()
	firing_locked = false
