extends RigidBody2D

@export var honey_value = 5
@export var heal_amount = GameBalance.PLAYER_HEAL["honey"]
@export var loot_id = ""

@onready var follower = $Path2D/PathFollow2D
@onready var collision = $Path2D/PathFollow2D/PickupArea/CollisionShape2D
@onready var anim = $AnimationPlayer
@onready var collision_honey = $CollisionShape2D

var game_state
var can_pickup = false
var collected = false

func _ready():
	game_state = get_node_or_null("/root/GameState")

	if loot_id == "":
		loot_id = name

	if game_state.collected_loot_ids.has(loot_id):
		queue_free()
		return

	game_state.heal_amount = heal_amount

	collision.disabled = true
	can_pickup = false

	anim.play("appear")
	await anim.animation_finished

	can_pickup = true
	collision.disabled = false

func _on_pickup_area_body_entered(body):
	if collected:
		return

	if not can_pickup:
		return

	if body.is_in_group("Player"):
		collected = true
		body.collect_items.collect_honey(honey_value)
		game_state.add_loot_collected(loot_id)
		queue_free()
