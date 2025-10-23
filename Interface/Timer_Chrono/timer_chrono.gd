extends Control

@export var start_time = 10.0  # temps de départ en secondes
var time_left = 0.0
var is_running = false

@onready var label = $Label
@onready var button = $Button

func _ready():
	# --- TAILLE DE LA POLICE ---
	label.add_theme_font_size_override("font_size", 70)  # taille du texte (modifiable)

	time_left = start_time
	_update_label()
	button.text = "Démarrer le chrono"
	button.pressed.connect(_on_button_pressed)

func _process(delta):
	if is_running:
		time_left -= delta
		if time_left <= 0:
			time_left = 0
			is_running = false
		_update_label()

func _update_label():
	var seconds = int(time_left)
	var centiemes = int(((time_left - seconds) * 100))
	label.text = str(seconds).pad_zeros(2) + "." + str(centiemes).pad_zeros(2)


func _on_button_pressed():
	start_chrono()

func start_chrono():
	time_left = start_time
	is_running = true
