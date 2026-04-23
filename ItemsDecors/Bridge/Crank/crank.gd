extends Area2D

signal activated

@onready var anim = $AnimationPlayer
@onready var col = $CollisionShape2D

var gs
var player_in_zone = false
var player = null
var is_activated = false
var is_using = false

func _ready():
	visible = false
	monitoring = false
	col.disabled = true

	gs = get_node("/root/GameState")
	gs.connect("all_seeds_collected", Callable(self, "_on_all_seeds_collected"))

func _on_all_seeds_collected():
	visible = true
	set_deferred("monitoring", true)
	col.set_deferred("disabled", false)

	if gs.player and gs.player.popups_mod:
		gs.player.popups_mod.show_info("✅ Manivelle débloquée !")

func _process(_delta):
	if not player_in_zone:
		return

	if is_activated:
		return

	if is_using:
		return

	if Input.is_action_just_pressed("interact"):
		activate()

func activate():
	if is_activated:
		return

	if is_using:
		return

	is_using = true
	player_in_zone = false

	if player:
		player.animation_mod.set_interact(true)

	if anim and anim.has_animation("turn"):
		anim.play("turn")

	await get_tree().create_timer(0.5).timeout

	if player:
		player.animation_mod.set_interact(false)
		player.popups_mod.show_info("Pont activé !")
	
	$ParticlesLoot.visible = false

	emit_signal("activated")

	is_activated = true
	is_using = false
	set_deferred("monitoring", false)
	col.set_deferred("disabled", true)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_zone = true
		player = body
		player.popups_mod.show_info("Appuie sur 'E' pour interagir")

func _on_body_exited(body):
	if body.is_in_group("Player"):
		body.popups_mod.show_info("")
		player_in_zone = false
		player = null
