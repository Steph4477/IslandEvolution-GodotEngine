extends CanvasLayer

signal finished

@onready var box  = $Box
@onready var text = $Box/MarginContainer/Text
@onready var anim = $AnimationPlayer
@onready var flower = $Flower
@onready var toucan = $Toucan

@export var lines = []
@export var auto_start := true           # Démarrer au _ready

# État interne
var chars_per_sec := 30          # Vitesse d’écriture
var pause_between_lines := 2.0   # Pause entre les lignes (s)
var hide_when_done := true       # Cacher le bandeau à la fin
var line_index := -1
var full_line := ""
var shown_chars := 0
var writing := false
var accum := 0.0
var pause_left := 0.0

# Ce flag sera mis à jour depuis le script du défi quand le signal challenge_win est émis
var challenge_win = false

func _ready():
	layer = 100
	text.text = ""
	flower.visible = false   # Par défaut, la fleur est masquée
	if auto_start:
		start()

func start(new_lines = null):
	if new_lines != null:
		lines = new_lines.duplicate()
	line_index = 0
	visible = true
	box.visible = true
	set_process(true)
	start_line()

func start_line():
	if line_index >= lines.size():
		end_dialogue()
		return
	full_line = str(lines[line_index])
	shown_chars = 0
	accum = 0.0
	writing = true
	pause_left = 0.0
	anim.play("speack")
	render()

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
				anim.play("idle")
				pause_left = pause_between_lines
			render()
	elif pause_left > 0.0:
		pause_left -= delta
		if pause_left <= 0.0:
			line_index += 1
			start_line()

func render():
	text.text = full_line.substr(0, shown_chars)

func end_dialogue():
	# Si le défi est gagné afficher la fleur à la fin du dialogue
	if challenge_win and flower:
		flower.visible = true
		
	if hide_when_done:
		box.visible = false
		visible = false
		
	set_process(false)
	emit_signal("finished")
