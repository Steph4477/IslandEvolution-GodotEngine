extends Node2D

@onready var anim = $AnimationPlayer
@onready var cycle_timer = $CycleTimer
@onready var window_timer = $WindowTimer

var camouflage_active = false


func _ready():
	anim.play("appear")
	cycle_timer.start()
	start_cycle()


func start_cycle():
	await get_tree().create_timer(0.5).timeout
	start_camouflage_window()
	window_timer.start()


func _on_cycle_timer_timeout():
	start_cycle()


func _on_window_timer_timeout():
	stop_camouflage_window()


func start_camouflage_window():
	camouflage_active = true
	show_info_popup("Moko appuie sur E pour attraper le camouflage !")


func stop_camouflage_window():
	camouflage_active = false
	hide_info_popup()


func show_info_popup(txt):
	var popup = get_tree().get_first_node_in_group("info_overlay_group")
	if popup == null:
		popup = preload("res://Interface/Popup/Info_popup/info_popup.tscn").instantiate()
		add_child(popup)
	popup.show_persistent(txt)


func hide_info_popup():
	var popup = get_tree().get_first_node_in_group("info_overlay_group")
	if popup == null:
		return
	popup.hide_persistent()
