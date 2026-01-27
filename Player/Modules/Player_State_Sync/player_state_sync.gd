extends Node

var p

func setup(player):
	p = player

func apply_from_gamestate():
	p.game_state = p.get_node_or_null("/root/GameState")
	if not p.game_state:
		return

	p.game_state.set_player(p)

	p.banane_count = p.game_state.banane_count
	p.honey_count = p.game_state.honey_count

	p.coco_count = p.game_state.coco_count
	p.bone_count = p.game_state.bone_count
	p.lance_count = p.game_state.lance_count

	# Aligné sur la logique GameState
	p.seed_count = p.game_state.collected_seeds

	p.can_fire_coco = p.game_state.can_fire_coco
	p.can_fire_lance = p.game_state.can_fire_lance
	p.can_fire_bone = p.game_state.can_fire_bone
	p.can_camouflage = p.game_state.can_camouflage

	p.can_ramp = p.game_state.ramp_unlocked
	p.can_sprint = p.game_state.sprint_unlocked

	# Recrée les listes après respawn / reload
	p.heal_potions.clear()
	for i in range(p.banane_count):
		p.heal_potions.append(p.game_state.heal_amount)

	p.honey_potions.clear()
	for j in range(p.honey_count):
		p.honey_potions.append(p.game_state.heal_amount)

	p.max_jump_count = 1
	if p.game_state.double_jump_unlocked:
		p.max_jump_count = 2
