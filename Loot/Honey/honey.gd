extends RigidBody2D

@export var honey_value = 5
@export var heal_amount = GameBalance.PLAYER_HEAL["honey"]

@onready var follower = $Path2D/PathFollow2D
@onready var collision = $Path2D/PathFollow2D/PickupArea/CollisionShape2D
@onready var anim = $AnimationPlayer
@onready var collision_honey = $CollisionShape2D

var game_state
var can_pickup = false

func _ready():
	collision.disabled = true
	can_pickup = false
	
	anim.play("appear")
	await anim.animation_finished
	
	can_pickup = true
	collision.disabled = false
	
	game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.heal_amount = heal_amount

func _on_pickup_area_body_entered(body):
	if body.is_in_group("Player"):
		body.collect_items.collect_honey(honey_value)
		queue_free()
