extends ParallaxLayer

@export var speed = Vector2(8.0, 0.0)
@onready var rect = $SkyRect

func _ready():
	_setup()

func _process(delta):
	motion_offset += speed * delta

func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_setup()

func _setup():
	if not rect or not rect.texture:
		return

	var vp = get_viewport_rect().size     # taille écran (ex: 1920x1080)
	# Le ciel couvre tout l'écran, et tuilera sans étirer la texture
	rect.position = Vector2(0, 0)
	rect.size = vp

	# Mirroring = taille affichée => duplication sans couture
	var displayed = rect.size
	displayed.x = round(displayed.x)
	displayed.y = round(displayed.y)
	motion_mirroring = displayed

	# Pas de décalage vertical pour le ciel
	motion_offset = Vector2.ZERO
