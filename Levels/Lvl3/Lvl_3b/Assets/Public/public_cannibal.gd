extends Node2D

enum Tribe {
	GREEN,
	BROWN,
	BLUE
}

@export var tribe = Tribe.GREEN
@export var random_flip = true
@export var auto_start_anim = true

@onready var anim = $AnimationPlayer
@onready var change_anim_timer = $ChangeAnimTimer

var green_anims = [
	"green_idle",
	"green_idle",
	"green_cheer",
	"green_shout",
	"green_weapon"
]

var brown_anims = [
	"brown_idle",
	"brown_idle",
	"brown_cheer",
	"brown_shout",
	"brown_weapon"
]

var blue_anims = [
	"blue_idle",
	"blue_idle",
	"blue_cheer",
	"blue_shout",
	"blue_weapon"
]


func _ready():

	add_to_group("public_cannibal")

	anim.active = true
	change_anim_timer.stop()

	if random_flip:
		if randi() % 2 == 0:
			scale.x *= -1

	set_idle_pose()

	if auto_start_anim:
		start_public_anim()
	else:
		stop_public_anim()


func start_public_anim():

	anim.active = true

	play_random_anim()

	change_anim_timer.wait_time = randf_range(1.2, 3.0)
	change_anim_timer.start()


func stop_public_anim():

	change_anim_timer.stop()

	set_idle_pose()

	anim.pause()


func set_idle_pose():

	anim.active = true

	if tribe == Tribe.GREEN:
		anim.play("green_idle")

	elif tribe == Tribe.BROWN:
		anim.play("brown_idle")

	elif tribe == Tribe.BLUE:
		anim.play("blue_idle")

	anim.seek(0.0, true)
	anim.advance(0.0)


func play_random_anim():

	var anim_list = []

	if tribe == Tribe.GREEN:
		anim_list = green_anims

	elif tribe == Tribe.BROWN:
		anim_list = brown_anims

	elif tribe == Tribe.BLUE:
		anim_list = blue_anims

	var random_anim = anim_list.pick_random()

	anim.speed_scale = randf_range(0.85, 1.2)

	anim.play(random_anim)


func _on_change_anim_timer_timeout():

	play_random_anim()

	change_anim_timer.wait_time = randf_range(1.2, 3.0)

	change_anim_timer.start()
