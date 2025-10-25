extends RigidBody2D

@onready var area = $Area2D
var player = null
var pushing = false

func _ready():
	freeze = true
	gravity_scale = 0.0
	collision_layer = 2

	var gs = get_node("/root/GameState")
	player = gs.player
	gs.connect("player_updated", Callable(self, "_on_player_changed"))

func _on_player_changed(p):
	player = p

func _physics_process(_delta):
	if not player:
		return

	if pushing and Input.is_action_pressed("push_pull"):
		freeze = false
		collision_layer = 1
		sleeping = false

		if "velocity" in player:
			linear_velocity.x = player.velocity.x
	else:
		freeze = true
		collision_layer = 2
		linear_velocity.x = 0

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		pushing = true
		if "can_push_pull" in body:
			body.can_push_pull = true
		show_info_popup('Maintiens la touche "p" pour pousser ou tirer la caisse')

func _on_area_2d_body_exited(body):
	if body.is_in_group("Player"):
		pushing = false
		if "can_push_pull" in body:
			body.can_push_pull = false

func show_info_popup(txt):
	var popup = preload("res://Interface/Popup/Info_popup/info_popup.tscn").instantiate()
	add_child(popup)
	popup.show_info(txt)
