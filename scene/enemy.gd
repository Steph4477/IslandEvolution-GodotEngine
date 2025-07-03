extends AnimatedSprite2D

@export var damage: int = 99999
@export var damage_interval: float = 1.0  # secondes

var damaging := false
var target: Node = null


func _ready() -> void:
	play("pique")
func _on_Area2D_body_entered(body):
	if body.is_in_group("Player"):
		play("pique")
		target = body
		damaging = true
		start_damage_loop()

func _on_Area2D_body_exited(body):
	if body == target:
		play("idle")
		damaging = false
		target = null

func start_damage_loop() -> void:
	await get_tree().process_frame  # Sécurité : attend que tout soit bien en scène

	while damaging and target and is_instance_valid(target):
		if target.has_method("on_hit"):
			target.on_hit(damage)

			# Vérifie si le joueur a 0 PV
			if target != null and "pv" in target:
				if target.pv <= 0:
					await get_tree().create_timer(0.3).timeout  # petit délai visuel
					get_tree().reload_current_scene()
					return  # stop la boucle
		# Attendre la prochaine tick de dégâts
		if is_inside_tree():
			await get_tree().create_timer(damage_interval).timeout
		else:
			break
