extends Area2D

var collected = false
var player_in_zone = false
var player = null
var is_collecting = false

@onready var anim = $AnimationPlayer
@onready var fullSprite = $FullSprite
@onready var emptySprite = $EmptySprite

func _ready():
	var gs = get_node("/root/GameState")

	fullSprite.visible = true
	emptySprite.visible = false
	
	if gs.idole_collected:
		fullSprite.visible = false
		emptySprite.visible = true
		collected = true
		set_deferred("monitoring", false)
		
		gs.player.collect_items.collect_idole()
		
		if gs.hud:
			gs.hud.update_air_craft_checklist()

func _on_body_entered(body):
	if body.is_in_group("Player") and not collected and not is_collecting:
		fullSprite.visible = true
		emptySprite.visible = false
		player_in_zone = true
		player = body
		anim.play("appear_air")
		
		if player.popups_mod:
			player.popups_mod.show_info("Appuie sur 'E' pour récupérer l'idole de l'air")

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_in_zone = false
		player = null

		if not collected and not is_collecting:
			anim.stop()
		
		anim.play("RESET")
		

func _process(_delta):
	if not player_in_zone:
		return

	if is_collecting:
		return

	if Input.is_action_just_pressed("interact"):
		collect()

func collect():
	if collected:
		return

	if is_collecting:
		return

	is_collecting = true
	player_in_zone = false

	anim.stop()

	player.animation_mod.set_interact(true)
	await player.anim.animation_finished
	player.animation_mod.set_interact(false)

	$ParticlesLoot.visible = false
	fullSprite.visible = false
	emptySprite.visible = true

	collected = true
	player.collect_items.collect_idole()

	var gs = get_node("/root/GameState")
	if gs.hud:
		gs.hud.update_air_craft_checklist()

	set_deferred("monitoring", false)
	is_collecting = false
