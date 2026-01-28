extends Node2D

@export var dialogue_scene = preload("res://Interface/Dialogue/toucan_dialogue.tscn")

var has_spoken = false

func dialogue_toucan():
	# ✅ Empêche d'afficher plusieurs fois le dialogue
	if has_spoken:
		return
	has_spoken = true

	# 💬 Insertion du dialogue du toucan
	var dlg = dialogue_scene.instantiate()
	dlg.name = "DialogueUI"
	add_child(dlg)

	# 💬 Dialogue du toucan
	dlg.start([
		"Des symboles se sont allumés sur ton passage ?! ...",
		"Trouve la bonne combinaison et tu pourras sortir !"
	])

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		dialogue_toucan()
