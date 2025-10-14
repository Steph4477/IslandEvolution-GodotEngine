extends RigidBody2D

@export var speed := 1000
@export var life_time := 3.0
@export var damage := 100  # Dégâts infligés par la banane

var direction := 1  # 1 = droite, -1 = gauche

func start(pos: Vector2, dir: int) -> void:
	position = pos
	direction = dir
	linear_velocity = Vector2(speed * direction, 0)
	$Area2D/CollisionShape2D.disabled = false 
	call_deferred("_self_destruct") 
	
func _self_destruct() -> void:
	await get_tree().create_timer(life_time).timeout
	queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemies"):
		if body.has_method("on_hit"):
			body.on_hit(damage)
		if body.has_method("stone"): #assomement
			body.stone()
	else:
		print("Cible NON dans le groupe Enemies")

	$Area2D/CollisionShape2D.set_deferred("disabled", true)
	$Sprite.hide()
	queue_free()
