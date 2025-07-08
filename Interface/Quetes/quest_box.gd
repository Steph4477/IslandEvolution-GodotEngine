extends CanvasLayer

@onready var quest_sprite: Sprite2D = $QuestSprite
@onready var checkmark: Sprite2D = $Checkmark
@onready var anim = $AnimationPlayer

func _ready():
	quest_sprite.visible = true
	anim.play("rule")
	checkmark.visible = false

func show_quest():
	visible = true
	quest_sprite.visible = true
	checkmark.visible = false

func complete_quest():
	checkmark.visible = true
