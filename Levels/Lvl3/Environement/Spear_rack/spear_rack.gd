extends Area2D

@export var loot_id = ""
@export var lance_amount = 4

var gs
var already_looted = false

func _ready():
	gs = get_node("/root/GameState")

	if loot_id == "":
		loot_id = name

	if gs.collected_loot_ids.has(loot_id):
		$FullSprite.visible = false
		$CollisionPolygon2D.disabled = true
		already_looted = true
		return

	$FullSprite.visible = true

func _on_body_entered(body):
	if already_looted:
		return

	if body.name != "Player":
		return

	already_looted = true

	body.collect_items.collect_lance(lance_amount)

	gs.add_loot_collected(loot_id)

	$FullSprite.visible = false
	$CollisionPolygon2D.call_deferred("set_disabled", true)
