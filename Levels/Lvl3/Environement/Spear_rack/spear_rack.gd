extends Area2D

@export var lance_amount = 4
var gs

func _ready():
	gs = get_node("/root/GameState")
	$FullSprite.visible = true

func _on_body_entered(body):
	if body.name == "Player":
		gs.lance_count += lance_amount
		gs.has_lance = true
		gs.can_fire_lance = true
		
		# Sync direct avec Moko au loot
		if gs.player:
			gs.player.can_fire_lance = true
			gs.player.refresh_hud_buttons()
		
		if gs.hud and gs.hud.has_method("update_lance_display"):
			gs.hud.update_lance_display()
		
		$FullSprite.visible = false
