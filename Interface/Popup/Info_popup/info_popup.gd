extends CanvasLayer

@export var info_duration := 1.5
@export var max_messages := 6
@export var stack_width_ratio := 0.8
@export var vertical_position_ratio := 0.35
@export var font_size := 30

@onready var template_label = $InfoLabel
var stack
var persistent_label = null


func _ready():
	add_to_group("info_overlay_group")

	# gabarit (style)
	if not template_label.label_settings:
		template_label.label_settings = LabelSettings.new()
	template_label.label_settings.font_size = font_size
	template_label.visible = false

	# pile de messages
	stack = VBoxContainer.new()
	add_child(stack)

	# position/largeur
	var sz = get_viewport().get_visible_rect().size
	stack.size = Vector2(sz.x * stack_width_ratio, 0)
	stack.position = Vector2((sz.x - stack.size.x) / 2.0, sz.y * vertical_position_ratio)


func show_info(txt):
	var lbl = Label.new()
	lbl.label_settings = template_label.label_settings.duplicate()
	lbl.label_settings.font_size = font_size
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.custom_minimum_size.x = stack.size.x
	lbl.text = str(txt)
	lbl.modulate.a = 0.0

	stack.add_child(lbl)

	# limiter le nombre de messages
	while stack.get_child_count() > max_messages:
		stack.get_child(0).queue_free()

	# fade-in -> attente -> fade-out -> suppression
	var t = create_tween()
	t.tween_property(lbl, "modulate:a", 1.0, 0.1)
	t.tween_interval(info_duration)
	t.tween_property(lbl, "modulate:a", 0.0, 0.2)
	t.tween_callback(func(): lbl.queue_free())


func show_persistent(txt):
	if persistent_label == null:
		persistent_label = Label.new()
		persistent_label.label_settings = template_label.label_settings.duplicate()
		persistent_label.label_settings.font_size = font_size
		persistent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		persistent_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		persistent_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		persistent_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		persistent_label.custom_minimum_size.x = stack.size.x
		persistent_label.position = stack.position
		add_child(persistent_label)

	persistent_label.text = str(txt)
	persistent_label.visible = true


func hide_persistent():
	if persistent_label:
		persistent_label.visible = false
