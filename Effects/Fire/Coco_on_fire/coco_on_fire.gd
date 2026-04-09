extends Node2D

@onready var flame_core = $FlameCore
@onready var flame_glow = $FlameGlow

var current_velocity = Vector2.ZERO

func _ready():
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

	_setup_flame_core()
	_setup_flame_glow()

func _physics_process(_delta):
	_update_parent_velocity()

func _setup_flame_core():
	flame_core.process_material = _make_core_material()

func _setup_flame_glow():
	flame_glow.process_material = _make_glow_material()

func _update_parent_velocity():
	current_velocity = Vector2.ZERO

	if get_parent() == null:
		return

	if "linear_velocity" in get_parent():
		current_velocity = get_parent().linear_velocity
		return

	if "velocity" in get_parent():
		current_velocity = get_parent().velocity
		return

func _make_core_material():
	var particle_mat = ParticleProcessMaterial.new()
	particle_mat.direction = Vector3(0, -1, 0)
	particle_mat.spread = 16.0
	particle_mat.gravity = Vector3(0, -8, 0)
	particle_mat.initial_velocity_min = 20.0
	particle_mat.initial_velocity_max = 42.0
	particle_mat.angular_velocity_min = -10.0
	particle_mat.angular_velocity_max = 10.0
	particle_mat.orbit_velocity_min = -0.2
	particle_mat.orbit_velocity_max = 0.2
	particle_mat.radial_accel_min = -4.0
	particle_mat.radial_accel_max = 4.0
	particle_mat.linear_accel_min = 0.0
	particle_mat.linear_accel_max = 0.0
	particle_mat.damping_min = 0.0
	particle_mat.damping_max = 0.0
	particle_mat.scale_min = 0.3
	particle_mat.scale_max = 0.7
	particle_mat.hue_variation_min = -0.02
	particle_mat.hue_variation_max = 0.02
	particle_mat.color_ramp = _make_core_gradient()
	return particle_mat

func _make_glow_material():
	var particle_mat = ParticleProcessMaterial.new()
	particle_mat.direction = Vector3(0, -1, 0)
	particle_mat.spread = 28.0
	particle_mat.gravity = Vector3(0, -6, 0)
	particle_mat.initial_velocity_min = 10.0
	particle_mat.initial_velocity_max = 24.0
	particle_mat.angular_velocity_min = -5.0
	particle_mat.angular_velocity_max = 5.0
	particle_mat.orbit_velocity_min = -0.15
	particle_mat.orbit_velocity_max = 0.15
	particle_mat.radial_accel_min = -3.0
	particle_mat.radial_accel_max = 3.0
	particle_mat.linear_accel_min = 0.0
	particle_mat.linear_accel_max = 0.0
	particle_mat.damping_min = 0.0
	particle_mat.damping_max = 0.0
	particle_mat.scale_min = 0.85
	particle_mat.scale_max = 1.45
	particle_mat.hue_variation_min = -0.03
	particle_mat.hue_variation_max = 0.03
	particle_mat.color_ramp = _make_glow_gradient()
	return particle_mat

func _make_core_gradient():
	var texture = GradientTexture1D.new()
	var gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.18, 0.60, 1.0])
	gradient.colors = PackedColorArray([
		Color("fff6c9"),
		Color("ffbe5c"),
		Color("ff6a00"),
		Color(0.35, 0.08, 0.00, 0.0)
	])
	texture.gradient = gradient
	return texture

func _make_glow_gradient():
	var texture = GradientTexture1D.new()
	var gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.22, 0.75, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 0.92, 0.75, 0.35),
		Color(1.0, 0.70, 0.30, 0.24),
		Color(1.0, 0.28, 0.05, 0.10),
		Color(0.30, 0.08, 0.00, 0.0)
	])
	texture.gradient = gradient
	return texture
