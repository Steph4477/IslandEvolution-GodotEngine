extends AnimatedSprite2D

@export var damage: int = 2000
@export var damage_interval: float = 1.0  # secondes

var damaging := false
var target: Node = null
var damage_loop_running := false  # 🔁 Pour éviter plusieurs boucles en même temps

func _ready() -> void:
	play("idle")

func _on_Area2D_body_entered(body):
	if body.is_in_group("Player"):
		play("pique")
		target = body
		damaging = true
		if not damage_loop_running:
			start_damage_loop()

func _on_Area2D_body_exited(body):
	if body == target:
		play("idle")
		damaging = false
		target = null

func start_damage_loop() -> void:
	damage_loop_running = true
	await get_tree().process_frame  # sécurité

	while damaging and target and is_instance_valid(target):
		if target.has_method("on_hit"):
			target.on_hit(damage)

			# Optionnel : délai visuel après KO
			if target.pv <= 0:
				await get_tree().create_timer(0.3).timeout
				break  # 🔁 stoppe la boucle, mort confirmée

		# ⏱ Attente entre chaque tick
		await get_tree().create_timer(damage_interval).timeout

	damage_loop_running = false  # ✅ relance possible si on re-rentre
