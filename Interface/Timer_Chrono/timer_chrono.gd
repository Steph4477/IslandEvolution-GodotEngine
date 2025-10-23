extends Control
signal finished

@export var start_time = 20.0
var time_left = 0.0
var is_running = false

@onready var label = $Label

func _ready():
	visible = false
	label.add_theme_font_size_override("font_size", 70)
	time_left = start_time
	_update_label()

func _process(delta):
	if is_running:
		time_left -= delta
		if time_left <= 0:
			time_left = 0
			is_running = false
			_update_label()
			emit_signal("finished")  # informe ChronoZone
			return
		_update_label()

# --- API ---
func start_chrono():
	time_left = start_time
	is_running = true
	visible = true

func stop_chrono():
	is_running = false

func reset_chrono():
	time_left = start_time
	_update_label()

func hide_chrono():
	visible = false

# --- Affichage ---
func _update_label():
	var seconds = int(time_left)
	var centiemes = int((time_left - seconds) * 100)
	label.text = str(seconds).pad_zeros(2) + "." + str(centiemes).pad_zeros(2)
