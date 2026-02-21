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

	if body.name != "Player":
		return

	already_looted = true

	# Collecte côté Player (c'est lui qui met à jour GS + HUD)
	body.collect_items.collect_lance(lance_amount)

	# Visuel rack vide
	$FullSprite.visible = false

	# Désactive la collision APRES la frame physics (fix flushing queries)
	$CollisionPolygon2D.call_deferred("set_disabled", true)
