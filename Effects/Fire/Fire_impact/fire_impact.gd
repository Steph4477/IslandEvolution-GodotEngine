extends Node2D

@export var impact_scale = 2.0

@onready var burst = $Burst
@onready var glow = $Glow

func _ready():
	_setup_burst()
	_setup_glow()

func play_impact():
	scale = Vector2(impact_scale, impact_scale)
	burst.restart()
	glow.restart()

func _setup_burst():
	burst.process_material = _make_burst_material()

func _setup_glow():
	glow.process_material = _make_glow_material()

func _make_burst_material():
	var m = ParticleProcessMaterial.new()
	m.direction = Vector3(1, 0, 0)
	m.spread = 180.0
	m.gravity = Vector3(0, 6, 0)
	m.initial_velocity_min = 140.0
	m.initial_velocity_max = 260.0
	m.angular_velocity_min = -60.0
	m.angular_velocity_max = 60.0
	m.scale_min = 0.6
	m.scale_max = 1.2
	m.color_ramp = _make_burst_gradient()
	return m

func _make_glow_material():
	var m = ParticleProcessMaterial.new()
	m.direction = Vector3(1, 0, 0)
	m.spread = 180.0
	m.gravity = Vector3(0, 0, 0)
	m.initial_velocity_min = 30.0
	m.initial_velocity_max = 60.0
	m.scale_min = 0.8
	m.scale_max = 1.4
	m.color_ramp = _make_glow_gradient()
	return m

func _make_burst_gradient():
	var t = GradientTexture1D.new()
	var g = Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.6, 1.0])
	g.colors = PackedColorArray([
		Color("ffffffff"),
		Color("ffd27aff"),
		Color("ff7a1aff"),
		Color("00000000")
	])
	t.gradient = g
	return t

func _make_glow_gradient():
	var t = GradientTexture1D.new()
	var g = Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 0.8, 1.0])
	g.colors = PackedColorArray([
		Color("ffd27a88"),
		Color("ff9a4255"),
		Color("80200022"),
		Color("00000000")
	])

	t.gradient = g
	return t
