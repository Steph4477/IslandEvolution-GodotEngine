extends ParallaxLayer

@export var speed = Vector2(60.0, 0.0)   # courant horizontal
@export var offset_from_top = -1.0       # -1 = auto moitié basse. Sinon mets une valeur fixe (ex: 1054)
@onready var rect = $WaterRect

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

	var vp = get_viewport_rect().size     # ex: 1920x1080

	# Taille de l'eau = largeur écran, moitié hauteur
	var target_h = vp.y * 0.5
	rect.position = Vector2(0, 0)
	rect.size = Vector2(vp.x, target_h)

	# Mirroring = taille affichée de la zone eau (pas de couture)
	var displayed = rect.size
	displayed.x = round(displayed.x)
	displayed.y = round(displayed.y)
	motion_mirroring = displayed

	# Placement vertical : par défaut on colle l'eau à la moitié basse
	if offset_from_top >= 0.0:
		# positionne le layer à une distance fixe depuis le haut
		position.y = offset_from_top
	else:
		# auto : eau commence à mi-hauteur (moitié basse)
		position.y = vp.y * 0.5

	# Reset l'offset de départ
	motion_offset = Vector2.ZERO
