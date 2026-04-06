extends Node2D

@export var intensity = 1.0
@export var size = 1.0
@export var amount = 55

@onready var p = $Flame

func _ready():
	setup_fire()


func setup_fire():
	p.emitting = false
	p.amount = amount
	p.lifetime = 0.55
	p.one_shot = false
	p.preprocess = 0.35
	p.explosiveness = 0.0
	p.randomness = 0.35
	p.local_coords = false

	# =========================
	# TEXTURE
	# =========================
	# Utilise une texture flamme soft, mais évite un coeur blanc trop massif.
	p.texture = preload("res://Effects/Fire/fire.png")

	# =========================
	# PROCESS MATERIAL
	# =========================
	var mat = ParticleProcessMaterial.new()

	mat.direction = Vector3(0, -1, 0)
	mat.spread = 14.0

	mat.initial_velocity_min = 35.0 * intensity
	mat.initial_velocity_max = 65.0 * intensity

	mat.gravity = Vector3(0, -12, 0)

	mat.scale_min = 0.18 * size
	mat.scale_max = 0.42 * size

	var scale_curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 0.55))
	scale_curve.add_point(Vector2(0.25, 1.0))
	scale_curve.add_point(Vector2(0.7, 0.55))
	scale_curve.add_point(Vector2(1.0, 0.0))
	mat.scale_curve = scale_curve

	# Le color ramp pilote la couleur et la disparition sur la durée de vie.
	var ramp = Gradient.new()
	ramp.add_point(0.0, Color(1.0, 0.82, 0.35, 0.00))
	ramp.add_point(0.10, Color(1.0, 0.78, 0.28, 0.85))
	ramp.add_point(0.45, Color(1.0, 0.45, 0.08, 0.65))
	ramp.add_point(0.80, Color(0.85, 0.18, 0.02, 0.18))
	ramp.add_point(1.0, Color(0.0, 0.0, 0.0, 0.0))
	mat.color_ramp = ramp

	p.process_material = mat

	# =========================
	# MATERIAL 2D
	# =========================
	var canvas_mat = CanvasItemMaterial.new()
	canvas_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = canvas_mat

	# Très important : baisse globale pour éviter la surexposition.
	p.modulate = Color(1.0, 0.82, 0.62, 0.42)

	p.emitting = true
