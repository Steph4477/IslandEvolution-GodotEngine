extends Area2D

@export var lance_amount = 4
var gs
var already_looted = false

func _ready():
	gs = get_node("/root/GameState")
	$FullSprite.visible = true

func _on_body_entered(body):
	if already_looted:
		return

	if body.name == "Player":
		already_looted = true

		gs.lance_count += lance_amount
		gs.has_lance = true
		gs.can_fire_lance = true
		
		# Collecte côté Player 
		body.collect_items.collect_lance(lance_amount, true)
		
		# Sync direct avec Moko au loot
		gs.player.can_fire_lance = true
		if body.hud_mod:
			body.hud_mod.refresh_hud_buttons()
		#elif body.game_state and body.game_state.hud:
			#body.game_state.hud.refresh_hud_buttons()

		
		gs.hud.update_lance_display()

		# Visuel rack vide
		$FullSprite.visible = false

		# Désactive complètement la zone
		$CollisionPolygon2D.disabled = true
