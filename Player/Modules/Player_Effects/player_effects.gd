extends Node

var p

func setup(player):
	p = player

# ============================================================================
#                               STATUS EFFECTS
# ============================================================================

func apply_gaz():
	if p.is_gazed:
		return
	p.is_gazed = true
	p.speed *= 0.2
	await p.get_tree().create_timer(3).timeout
	p.speed /= 0.2
	p.is_gazed = false

func apply_web_effect():
	if p.is_web:
		return
	p.is_web = true
	p.speed *= 0.5
	await p.get_tree().create_timer(10).timeout
	p.speed /= 0.5
	p.is_web = false

func kill_by_plant():
	p.visible = false
