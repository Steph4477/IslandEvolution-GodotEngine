extends Node

var p = null
var info_scene = preload("res://Interface/Popup/Info_popup/info_popup.tscn")
var damage_scene = preload("res://Interface/Popup/Damage_popup/damage_popup.tscn")

func setup(player):
	p = player

func show_info(txt):
	var popup = p.get_tree().get_first_node_in_group("info_overlay_group")
	if popup == null:
		popup = info_scene.instantiate()
		p.add_child(popup)
	popup.show_info(txt)

func show_damage(amount):
	var popup = damage_scene.instantiate()
	p.add_child(popup)
	popup.position = Vector2(0, -30)
	popup.show_damage(amount)
