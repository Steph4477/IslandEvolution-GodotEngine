extends Node2D

@onready var flow = $flow
@onready var branch_collision = $StaticArea2D/CollisionShape2D

var flow_hidden = false

func _ready():
	flow.visible = true
	flow_hidden = false

func _on_chrono_zone_challenge_win():
	await get_tree().create_timer(0.8).timeout
	flow.visible = false
	flow_hidden = true
