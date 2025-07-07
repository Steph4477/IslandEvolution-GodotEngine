extends Node2D

@onready var anim = $AnimationPlayer
@onready var area = $Area2D
var can_damage := true

func set_active(active: bool) -> void:
	can_damage = active

func _ready() -> void:
	anim.play("Harrow")  # Animation en boucle ou initiale


func _on_area_2d_body_entered(body: Node2D) -> void:
	if not can_damage:
		return
	if not body.is_in_group("Player"):
		return

	var game_state = get_node_or_null("/root/GameState")
	if not game_state:
		return

	if body.has_method("on_hit") and not body.is_dead:
		var damage = game_state.player.max_pv  # Inflige les PV max
		body.on_hit(damage)
	
	
