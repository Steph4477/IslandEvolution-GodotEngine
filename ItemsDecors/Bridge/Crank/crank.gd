extends Area2D

signal activated

@onready var anim = $AnimationPlayer
@onready var col = $CollisionShape2D

var gs 

func _ready():
	visible = false
	monitoring = false
	col.disabled = true

	gs = get_node("/root/GameState")
	gs.connect("all_seeds_collected", Callable(self, "_on_all_seeds_collected"))

func _on_all_seeds_collected():
	visible = true
	set_deferred("monitoring", true) # physique → deferred
	col.set_deferred("disabled", false) # physique (moteur de collision) → deferred
	show_info_popup("✅ Manivelle débloquée !")

func _process(_delta):
	if Input.is_action_just_pressed("interact"):
		activate()

func activate():
	if anim and anim.has_animation("turn"):
		anim.play("turn")
	show_info_popup("Pont activé !")
	emit_signal("activated")  # envoie au Bridge parent

func _on_body_entered(body):
	if body.is_in_group("Player"):
		show_info_popup("Appuie sur 'E' pour interagir")

func _on_body_exited(body):
	if body.is_in_group("Player"):
		show_info_popup("")

func show_info_popup(txt):
	var popup = get_tree().get_first_node_in_group("info_overlay_group")
	if popup == null:
		popup = preload("res://Interface/Popup/Info_popup/info_popup.tscn").instantiate()
		get_tree().root.add_child(popup)
	popup.show_info(txt)
