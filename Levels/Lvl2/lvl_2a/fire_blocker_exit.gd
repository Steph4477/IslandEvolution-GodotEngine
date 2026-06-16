extends Node2D

@onready var wall_collision = $StaticBody2D/CollisionShape2D

func _ready():
	refresh_blocker()

func _process(_delta):
	refresh_blocker()

func refresh_blocker():
	var gs = get_node("/root/GameState")

	if gs.fire_buff_unlocked:
		wall_collision.disabled = true
	else:
		wall_collision.disabled = false

func _on_popup_zone_body_entered(body):
	if body.name != "Player":
		return

	var gs = get_node("/root/GameState")

	if gs.fire_buff_unlocked:
		return

	if body.popups_mod:
		body.popups_mod.show_info("🔥 Il te manque le pouvoir du feu")

func _on_popup_zone_body_exited(body):
	if body.name != "Player":
		return
