extends Node2D

enum Tribe {
	GREEN,
	BROWN,
	BLUE
}

@export var tribe = Tribe.GREEN
@export var random_flip = true

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

	if random_flip:
		if randi() % 2 == 0:
			scale.x *= -1

	play_random_anim()

	change_anim_timer.wait_time = randf_range(1.2, 3.0)
	change_anim_timer.start()


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
