extends EnemyBase
class_name EnemySwimBase

@export var swim_speed = 120.0
@export var min_change_time = 1.5
@export var max_change_time = 3.5

var dir = Vector2.ZERO
var min_bound = Vector2.ZERO
var max_bound = Vector2.ZERO

var rotator
var patrol_timer
var bounds_shape

func _ready():
	super._ready()

	rotator = $Rotator
	patrol_timer = $PatrolTimer
	bounds_shape = $Bounds/CollisionShape2D

	update_bounds()
	set_random_swim_dir()

# =========================
# MOVE
# =========================
func move_swim(delta):
	global_position += dir * swim_speed * delta
	clamp_to_bounds()

# =========================
# DIR
# =========================
func set_random_swim_dir():
	var x = randf() * 2 - 1
	var y = randf() * 2 - 1
	dir = Vector2(x, y).normalized()

# =========================
# BOUNDS
# =========================
func update_bounds():
	var ext = bounds_shape.shape.extents
	var center = bounds_shape.global_position

	min_bound = center - ext
	max_bound = center + ext

func clamp_to_bounds():
	var touched = false

	if global_position.x < min_bound.x:
		global_position.x = min_bound.x
		touched = true
	elif global_position.x > max_bound.x:
		global_position.x = max_bound.x
		touched = true

	if global_position.y < min_bound.y:
		global_position.y = min_bound.y
		touched = true
	elif global_position.y > max_bound.y:
		global_position.y = max_bound.y
		touched = true

	if touched:
		set_random_swim_dir()

# =========================
# FLIP
# =========================
func update_flip():
	if dir.x < -0.1:
		rotator.scale.x = -1
	elif dir.x > 0.1:
		rotator.scale.x = 1

# =========================
# ANIM
# =========================
func play_swim():
	if anim.current_animation != "swim":
		anim.play("swim")

# =========================
# TIMER
# =========================
func _on_patrol_timer_timeout():
	set_random_swim_dir()
	patrol_timer.start()
