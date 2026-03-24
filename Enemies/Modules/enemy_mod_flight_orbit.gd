extends RefCounted
class_name EnemyModFlightOrbit

var enemy = null
var orbit_angle = 0.0
var orbit_time_left = 0.0
var osc_time = 0.0

func setup(e):
	enemy = e

func start():
	orbit_time_left = enemy.orbit_duration
	osc_time = 0.0
	orbit_angle = (enemy.global_position - enemy.get_target_position()).angle()

func update(delta):
	orbit_time_left -= delta
	orbit_angle += enemy.orbit_angular_speed * delta
	osc_time += delta

	var wobble_angle = sin(osc_time * TAU * enemy.osc_angle_frequency) * enemy.osc_angle_amplitude
	var a = orbit_angle + wobble_angle

	var radial_boost = 1.0 + sin(osc_time * TAU * enemy.osc_radial_frequency) * (enemy.osc_radial_amplitude / enemy.orbit_radius_x)

	var rx = enemy.orbit_radius_x * radial_boost
	var ry = enemy.orbit_radius_y * radial_boost

	var target = enemy.get_target_position()
	var orbit_pos = target + Vector2(cos(a) * rx, sin(a) * ry)
	var dir = (orbit_pos - enemy.global_position).normalized()

	enemy.flight_velocity = dir * enemy.chase_speed
	enemy.play_flight_anim("flight")

func is_finished():
	return orbit_time_left <= 0.0
