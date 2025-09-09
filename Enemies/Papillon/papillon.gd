extends CharacterBody2D

@export var show_duration := 1.8

@onready var sprite = $Sprite
@onready var anim = $AnimationPlayer
@onready var timer = $Timer
@onready var area = $Area2D

func _ready():
	# Caché au départ
	#sprite.visible = false
	# Timer en one_shot pour auto-s'arrêter
	timer.one_shot = true
	# Connecte le signal une seule fois si pas déjà fait (au cas où)
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)


func start_show():
	# Affiche, lance l’anim une fois, puis démarre le compte à rebours
	#sprite.visible = true
	if anim.current_animation != "fly" or not anim.is_playing():
		anim.play("fly")
	timer.wait_time = show_duration
	timer.start()

func _on_timer_timeout():
	queue_free()

func _on_area_2d_body_entered(body):
	# Affiche lors de la collision et démarre le timer
	print("collision avec :", body)
	start_show()
