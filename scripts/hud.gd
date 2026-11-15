extends CanvasLayer

const JOYSTICK_SCRIPT = preload("res://scripts/joystick.gd")

var ship: Variant
var labels := {}
var screen_size := Vector2.ZERO
var joystick_view: Control
var left_touch := -1
var right_touch := -1
var left_value := Vector2.ZERO
var right_value := Vector2.ZERO

func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	_build_ui()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)
	var panel := ColorRect.new()
	panel.position = Vector2(18, 18)
	panel.size = Vector2(270, 142)
	panel.color = Color(0.015, 0.035, 0.075, 0.72)
	root.add_child(panel)
	var title := Label.new()
	title.text = "COSMOS  //  FLIGHT SYSTEMS"
	title.position = Vector2(30, 24)
	title.add_theme_color_override("font_color", Color(0.25, 0.8, 1.0))
	root.add_child(title)
	for i in range(6):
		var label := Label.new()
		label.position = Vector2(30, 48 + i * 18)
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0))
		root.add_child(label)
		labels[i] = label
	var hint := Label.new()
	hint.text = "LEFT: FLIGHT DIRECTION                         RIGHT: THROTTLE / SPEED"
	hint.position = Vector2(screen_size.x * 0.5 - 250, screen_size.y - 28)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.72, 0.84, 0.96))
	root.add_child(hint)
	joystick_view = Control.new()
	joystick_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	joystick_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_view.set_script(JOYSTICK_SCRIPT)
	root.add_child(joystick_view)
	var cross := Label.new()
	cross.text = "⊕"
	cross.position = Vector2(screen_size.x * 0.5 - 12, screen_size.y * 0.5 - 18)
	cross.add_theme_font_size_override("font_size", 30)
	cross.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 0.7))
	root.add_child(cross)

func _process(_delta: float) -> void:
	if not is_instance_valid(ship):
		return
	labels[0].text = "ALTITUDE     %7.2f km" % ship.altitude_km()
	labels[1].text = "VELOCITY     %7.3f km/s" % ship.speed_kms()
	labels[2].text = "ACCEL        %7.2f m/s2" % ship.acceleration.length()
	labels[3].text = "GRAVITY      %7.3f m/s2" % ship.gravity_value()
	labels[4].text = "AIR DENSITY  %.5f kg/m3" % ship.air_density()
	labels[5].text = "FUEL         %5.1f%%" % (ship.fuel / ship.fuel_capacity * 100.0)

func _apply_sticks() -> void:
	if not is_instance_valid(ship):
		return
	ship.steering = Vector2(-left_value.x, left_value.y)
	ship.throttle = clampf(-right_value.y, -1.0, 1.0)
	if is_instance_valid(joystick_view):
		joystick_view.left_value = left_value
		joystick_view.right_value = right_value
		joystick_view.queue_redraw()

func _input(event: InputEvent) -> void:
	if not is_instance_valid(ship):
		return
	if event is InputEventScreenTouch:
		var left_center := Vector2(screen_size.x * 0.16, screen_size.y * 0.78)
		var right_center := Vector2(screen_size.x * 0.84, screen_size.y * 0.78)
		if event.pressed:
			if event.position.distance_to(left_center) < screen_size.y * 0.23 and left_touch == -1:
				left_touch = event.index
				_update_stick(event.position, true)
			elif event.position.distance_to(right_center) < screen_size.y * 0.23 and right_touch == -1:
				right_touch = event.index
				_update_stick(event.position, false)
		else:
			if event.index == left_touch:
				left_touch = -1
				left_value = Vector2.ZERO
			if event.index == right_touch:
				right_touch = -1
				right_value = Vector2.ZERO
			_apply_sticks()
	elif event is InputEventScreenDrag:
		if event.index == left_touch:
			_update_stick(event.position, true)
		elif event.index == right_touch:
			_update_stick(event.position, false)

func _update_stick(position: Vector2, is_left: bool) -> void:
	var center := Vector2(screen_size.x * (0.16 if is_left else 0.84), screen_size.y * 0.78)
	var radius := screen_size.y * 0.115
	var value := ((position - center) / radius).limit_length(1.0)
	if is_left:
		left_value = value
	else:
		right_value = value
	_apply_sticks()
