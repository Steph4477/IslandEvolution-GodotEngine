extends Area2D

var collected = false
@onready var anim = $AnimationPlayer
@onready var fullSprite = $FullSprite
@onready var emptySprite = $EmptySprite
@onready var collision = $CollisionShape2D

func _ready():
	var gs = get_node("/root/GameState")
	fullSprite.visible = true
	emptySprite.visible = false
	
	if gs.idole_collected:
		fullSprite.visible = false
		emptySprite.visible = true
		collected = true
		collision.set_deferred("disabled", true)
		set_deferred("monitoring", false)

func _on_body_entered(body):
	if collected:
		return

	if body.is_in_group("Player"):
		collected = true
		collision.set_deferred("disabled", true)
		set_deferred("monitoring", false)

		anim.play("appear_air")
		await anim.animation_finished

		fullSprite.visible = false
		emptySprite.visible = true

		body.collect_items.collect_idole()

		var gs = get_node("/root/GameState")
		if gs.hud:
			gs.hud.update_air_craft_checklist()
