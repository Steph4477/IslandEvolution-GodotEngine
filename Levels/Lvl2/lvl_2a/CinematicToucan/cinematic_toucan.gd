extends Node2D

@onready var loot_scene = preload("res://Items/Fire_Recipe/fire_recipe.tscn")
@onready var anim = $AnimationPlayer
@onready var toucan = $Toucan
@onready var box  = $Box
@onready var text = $Box/MarginContainer/Text

# Réglages via l’inspecteur
@export var lines = [
	"Pas mal pour un singe !",
	"Tu as trouvé bois et pierre",
	"Je commence à être impressionné…",
	"Tiens, prends ça !",
	"À toi de maîtriser le feu maintenant."
]

@export var auto_start = true           # Démarrer au _ready
@export var chars_per_sec = 30          # Vitesse d’écriture
@export var pause_between_lines = 1.0   # Pause entre les lignes (s)
@export var hide_when_done = true       # Cacher le bandeau à la fin

var player
var gs

# --- Sous-titre ---
var line_index = -1
var full_line = ""
var shown_chars = 0
var writing = false
var accum = 0.0
var pause_left = 0.0

func _ready():
	gs = get_node("/root/GameState")
	player = gs.player
	
	start_cinematic()
	
	await get_tree().create_timer(4).timeout
	start()
	await get_tree().create_timer(4.4).timeout
	loot_craft()  

func start_cinematic():
	player.disable_controls()
	anim.play("intro")

func start(new_lines = null):
	# Lance le dialogue. Si new_lines est fourni, il remplace lines.
	if new_lines != null:
		lines = new_lines.duplicate()
	line_index = 0
	visible = true
	box.visible = true
	set_process(true)
	_start_line()

func _start_line():
	if line_index >= lines.size():
		_end_dialogue()
		return
	full_line = str(lines[line_index])
	shown_chars = 0
	accum = 0.0
	writing = true
	pause_left = 0.0     
	_render()

func _process(delta):
	if not box.visible:
		return

	if writing:
		accum += delta
		var step = int(accum * chars_per_sec)
		if step > 0:
			accum -= float(step) / float(chars_per_sec)
			shown_chars += step
			if shown_chars >= full_line.length():
				shown_chars = full_line.length()
				writing = false
				pause_left = pause_between_lines
			_render()
	elif pause_left > 0.0:
		pause_left -= delta
		if pause_left <= 0.0:
			line_index += 1
			_start_line()

func _render():
	text.text = full_line.substr(0, shown_chars)

func _end_dialogue():
	if hide_when_done:
		box.visible = false
		visible = false
	set_process(false)
	player.enable_controls()

func loot_craft():
	var loot = preload("res://Items/Fire_Recipe/fire_recipe.tscn").instantiate()
	var marker = $LootSpawn
	get_tree().current_scene.add_child(loot)
	
	# Position sur le marker
	loot.global_position = marker.global_position
