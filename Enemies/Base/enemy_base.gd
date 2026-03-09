extends CharacterBody2D
class_name EnemyBase

@export var max_hp = 100
@export var damage = 10

var gs = null
var player = null

var pv = 0
var is_dead = false
var is_attacking = false
var in_melee = false

func _ready():
	pv = max_hp
	$HealthBar/ProgressBar.max_value = max_hp
	$HealthBar/ProgressBar.value = pv
	find_player()

func find_player():
	gs = get_node("/root/GameState")
	player = gs.player
	gs.connect("player_updated", Callable(self, "_on_player_changed"))

func _on_player_changed(new_player):
	player = new_player

func on_hit(damage_taken):

	if is_dead:
		return

	pv -= damage_taken
	$HealthBar/ProgressBar.value = max(pv,0)

	_show_damage_popup(damage_taken)

	if pv <= 0:
		die()

func _show_damage_popup(amount):

	var scene = preload("res://Interface/Popup/Damage_popup/damage_popup.tscn")
	var popup = scene.instantiate()

	$HealthBar.add_child(popup)

	popup.position = Vector2(0,-30)
	popup.scale.x = 1
	popup.show_damage(amount)

func die():

	is_dead = true
	velocity = Vector2.ZERO

	queue_free()
