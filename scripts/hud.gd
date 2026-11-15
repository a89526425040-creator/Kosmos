extends CanvasLayer

var ship: Variant
var labels := {}
var screen_size := Vector2.ZERO

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
		var l := Label.new()
		l.position = Vector2(30, 48 + i * 18)
		l.add_theme_font_size_override("font_size", 13)
		l.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0))
		root.add_child(l)
		labels[i] = l
	var hint := Label.new()
	hint.text = "W/S THRUST   ARROWS PITCH/YAW   Q/E ROLL"
	hint.position = Vector2(18, screen_size.y - 28)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.55, 0.72, 0.9))
	root.add_child(hint)
	_make_button(root, "THR+", Vector2(18, screen_size.y - 210), "forward")
	_make_button(root, "THR−", Vector2(18, screen_size.y - 160), "back")
	_make_button(root, "UP", Vector2(screen_size.x - 88, screen_size.y - 210), "up")
	_make_button(root, "DOWN", Vector2(screen_size.x - 88, screen_size.y - 160), "down")
	_make_button(root, "ROLL−", Vector2(screen_size.x - 168, screen_size.y - 105), "roll_left")
	_make_button(root, "ROLL+", Vector2(screen_size.x - 88, screen_size.y - 105), "roll_right")
	var cross := Label.new()
	cross.text = "⊕"
	cross.position = Vector2(screen_size.x * 0.5 - 12, screen_size.y * 0.5 - 18)
	cross.add_theme_font_size_override("font_size", 30)
	cross.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 0.7))
	root.add_child(cross)

func _make_button(root: Control, caption: String, pos: Vector2, action: String) -> void:
	var b := Button.new()
	b.text = caption
	b.position = pos
	b.size = Vector2(68, 42)
	b.modulate = Color(0.55, 0.85, 1.0, 0.82)
	b.button_down.connect(func(): _set_action(action, true))
	b.button_up.connect(func(): _set_action(action, false))
	root.add_child(b)

func _set_action(action: String, pressed: bool) -> void:
	if not is_instance_valid(ship): return
	match action:
		"forward": ship.throttle = 1.0 if pressed else 0.0
		"back": ship.throttle = -1.0 if pressed else 0.0
		"up": ship.lateral_input.y = 1.0 if pressed else 0.0
		"down": ship.lateral_input.y = -1.0 if pressed else 0.0
		"roll_left": ship.roll_input = -1.0 if pressed else 0.0
		"roll_right": ship.roll_input = 1.0 if pressed else 0.0

func _process(_delta: float) -> void:
	if not is_instance_valid(ship): return
	labels[0].text = "ALTITUDE     %7.2f km" % ship.altitude_km()
	labels[1].text = "VELOCITY     %7.3f km/s" % ship.speed_kms()
	labels[2].text = "ACCEL        %7.2f m/s2" % ship.acceleration.length()
	labels[3].text = "GRAVITY      %7.3f m/s2" % ship.gravity_value()
	labels[4].text = "AIR DENSITY  %.5f kg/m3" % ship.air_density()
	labels[5].text = "FUEL         %5.1f%%" % (ship.fuel / ship.fuel_capacity * 100.0)

func _input(event: InputEvent) -> void:
	if not is_instance_valid(ship): return
	if event is InputEventScreenTouch:
		if not event.pressed:
			ship.steering = Vector2.ZERO
	elif event is InputEventScreenDrag:
		var p: Vector2 = event.position
		var center_x := screen_size.x * (0.25 if p.x < screen_size.x * 0.5 else 0.75)
		ship.steering = Vector2(-(p.x - center_x) / 180.0, (p.y - screen_size.y * 0.7) / 180.0).limit_length(1.0)
