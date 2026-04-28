extends Node2D

var collected = false
var gs

@onready var anim = $AnimationPlayer
@onready var col = $Path2D/PathFollow2D/Area2D/CollisionShape2D

func _ready():
	gs = get_node("/root/GameState")

	if gs.fire_recipe_unlocked:
		queue_free()
		return

	# --- Désactive collision au spawn ---
	col.disabled = true

	# --- Délai 0.8s ---
	await get_tree().create_timer(0.8).timeout

	# --- Réactive collision ---
	col.disabled = false

func _on_area_2d_body_entered(body):
	if collected:
		return
	
	if body.is_in_group("Player"):
		collected = true

		body.collect_items.collect_fire_recipe()

		gs.fire_recipe_unlocked = true
		gs.fire_craft_revealed = true

		body.popups_mod.show_info("📜 Recette récupérée")

		if gs.hud:
			gs.hud.appear_fire_craft_quest()
			gs.hud.update_fire_craft_checklist()

		if not gs.fire_recipe_dialog_shown:
			gs.fire_recipe_dialog_shown = true

		queue_free()
