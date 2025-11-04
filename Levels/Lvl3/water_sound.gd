extends AudioStreamPlayer

@export var auto_start = true
@export var start_delay = 0.0
@export var use_music_bus_if_exists = true   # sinon forcera Master

func _ready():
	# --- PANIC UNMUTE (au cas où tes bus sont mutés) ---
	_unmute_buses()

	# --- Bus propre (si "Music" n'existe pas, on force Master) ---
	var music_idx = AudioServer.get_bus_index("Water")
	if use_music_bus_if_exists and music_idx != -1:
		bus = "Water"
	else:
		bus = "Master"

	# --- Volume franc le temps du test ---
	volume_db = 0.0

	# --- Boucle forcée (WAV/OGG) ---
	_ensure_loop()

	# --- Lecture garantie (avec léger délai possible) ---
	if auto_start:
		if start_delay > 0.0:
			await get_tree().create_timer(start_delay).timeout
		stop()
		play()

	# --- Debug utile dans la console ---
	print("[MUSIC] bus=", bus, " has_stream=", stream != null, " playing=", playing)

func _ensure_loop():
	if stream:
		if stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		elif "loop" in stream:
			stream.loop = true

func _unmute_buses():
	var m = AudioServer.get_bus_index("Master")
	if m != -1:
		AudioServer.set_bus_mute(m, false)
		AudioServer.set_bus_volume_db(m, 0.0)
	var sfx = AudioServer.get_bus_index("SFX")
	if sfx != -1:
		AudioServer.set_bus_mute(sfx, false)
		AudioServer.set_bus_volume_db(sfx, 0.0)
	var music = AudioServer.get_bus_index("Water")
	if music != -1:
		AudioServer.set_bus_mute(music, false)
		AudioServer.set_bus_volume_db(music, 0.0)
