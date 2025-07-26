extends CharacterBody2D

@export var lance_scene: PackedScene = preload("res://Tir/lance_trap.tscn")
@export var fire_interval := 3.0
@export var total_shots := 10
@export var move_speed := 100.0
@export var melee_damage := 50

var player: Node2D
var shot_count := 0
var is_melee_mode := false
var is_attacking := false

@onready var timer = $Timer
@onready var anim = $AnimationPlayer
@onready var spawn_lance = $Lance
@onready var melee_zone = $melee_zone

func _ready():
	find_and_bind_player()
	timer.wait_time = fire_interval
	timer.start()

func find_and_bind_player():
	var gs = get_node_or_null("/root/GameState")
	if gs:
		player = gs.player
		gs.connect("player_updated", Callable(self, "_on_player_changed"))

func _on_player_changed(new_player: Node):
	player = new_player

func _physics_process(delta):
	if is_melee_mode and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * move_speed
		move_and_slide()

func _on_timer_timeout():
	if not is_instance_valid(player) or is_melee_mode:
		return

	if shot_count >= total_shots:
		timer.stop()
		return

	shot_count += 1
	print("🏹 [Pygmee] Lance tirée #", shot_count)

	anim.play("attack")
	await get_tree().create_timer(0.2).timeout

	var lance = lance_scene.instantiate()
	get_tree().current_scene.add_child(lance)
	lance.global_position = spawn_lance.global_position

	await anim.animation_finished
	await get_tree().create_timer(0.5).timeout 
	anim.play("idle")

func _on_melee_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not is_melee_mode:
		print("🗡️ [Pygmee] Moko entré dans la zone de mêlée !")
		is_melee_mode = true
		timer.stop()
		await attack_melee_loop()

func _on_melee_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") and is_melee_mode:
		print("🏹 [Pygmee] Moko sorti de la zone de mêlée. Reprise des tirs.")
		is_melee_mode = false
		shot_count = 0
		timer.start()

func attack_melee_loop() -> void:
	while is_melee_mode and is_instance_valid(player):
		if is_attacking:
			await get_tree().process_frame
			continue

		is_attacking = true
		print("💢 [Pygmee] Attaque mêlée déclenchée")
		#anim.play("attack_melee")

		#await anim.animation_finished
		print("💢 [Pygmee] Animation attaque mêlée terminée")

		# On vérifie si le joueur est dans la zone de collision (Area2D)
		var bodies = $MeleeZone.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("Player"):
				print("💥 [Pygmee] Moko touché via collision !")
				if "on_hit" in body:
					body.on_hit(melee_damage)
				else:
					print("❌ [Pygmee] Moko n'a pas de méthode on_hit()")

		anim.play("idle")
		is_attacking = false

		await get_tree().create_timer(1.0).timeout
