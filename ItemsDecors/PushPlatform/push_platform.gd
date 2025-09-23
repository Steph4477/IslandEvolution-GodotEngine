extends RigidBody2D

@onready var area = $Area2D

var player = null

# Flag unique vrai si le joueur est dans la zone de la caisse
# et donc autorisé à déclencher l’anim "push"
var pushing = false   

func _ready():
	# La caisse est figée et ne tombe pas par défaut
	freeze = true
	gravity_scale = 0.0
	collision_layer = 2   # layer 2 = "platform" (Moko peut marcher dessus mais pas pousser)

	# 🔎 Récupère le player via GameState
	var gs = get_node("/root/GameState")
	player = gs.player
	# Si jamais le player est recréé (perte de vie), on le met à jour 
	gs.connect("player_updated", Callable(self, "_on_player_changed"))

func _on_player_changed(p):
	# Quand GameState envoie le nouveau player (après respawn)
	player = p

func _physics_process(_delta):
	# si pas de player, on fait rien
	if not player:
		return

	var anim = player.get_node("Node2D/Anim")

	# ✅ Si le joueur est dans la zone ET qu’il maintient "push"
	if pushing and Input.is_action_pressed("push"):
		freeze = false              # la caisse devient poussable
		collision_layer = 1         # interaction physique avec Moko
		await get_tree().process_frame  # attend une frame pour écraser "walk"
		anim.play("push")           # force l’anim "push"
	else:
		# ❌ la caisse redevient figée et solide
		freeze = true
		collision_layer = 2

# Affiche un popup d’info au joueur
func show_info_popup(txt) :
	var popup = preload("res://ItemsDecors/info_popup.tscn").instantiate()
	add_child(popup)
	popup.show_info(txt)

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		pushing = true   # active le mode "push"
		show_info_popup('Maintiens la touche "P" enfoncée pour pousser la caisse')


func _on_area_2d_body_exited(body):
	if body.is_in_group("Player"):
		pushing = false  # le joueur reprend ses anims normales
