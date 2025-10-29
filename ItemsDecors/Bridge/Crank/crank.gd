extends Area2D

signal activated

@export var interact_action = "interact"
@onready var anim = $AnimationPlayer
@onready var col = $CollisionShape2D

var player_inside = false
var used = false
var gs = null

# même helper que player.gd
func show_info_popup(txt):
	var popup = get_tree().get_first_node_in_group("info_overlay_group")
	if popup == null:
		popup = preload("res://Interface/Popup/Info_popup/info_popup.tscn").instantiate()
		add_child(popup)
	popup.show_info(txt)

func _ready():
	# caché / inactif par défaut
	visible = false
	monitoring = false
	if col:
		col.disabled = true

	# écoute uniquement le signal du GameState
	gs = get_node_or_null("/root/GameState")
	if gs and not gs.is_connected("all_seeds_collected", Callable(self, "_on_all_seeds_collected")):
		gs.connect("all_seeds_collected", Callable(self, "_on_all_seeds_collected"))

func _on_all_seeds_collected():
	# déverrouille à la réception du signal GS
	visible = true
	monitoring = true
	if col:
		col.disabled = false
	show_info_popup("✅ Manivelle débloquée !")

func _process(_delta):
	if used:
		return
	if player_inside and Input.is_action_just_pressed(interact_action):
		if not visible:
			return
		_activate()

func _activate():
	used = true
	if anim and anim.has_animation("turn"):
		anim.play("turn")
	show_info_popup("Pont activé !")
	emit_signal("activated")

func _on_body_entered(body):
	if body.is_in_group("Player") or body.name == "Player":
		player_inside = true
		if visible:
			show_info_popup("Appuie sur 'E' pour interagir")

func _on_body_exited(body):
	if body.is_in_group("Player") or body.name == "Player":
		player_inside = false
		show_info_popup("")
