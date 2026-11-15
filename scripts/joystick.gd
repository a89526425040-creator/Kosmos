extends Control

var left_value := Vector2.ZERO
var right_value := Vector2.ZERO

func _draw() -> void:
	var radius := size.y * 0.115
	var left_center := Vector2(size.x * 0.16, size.y * 0.78)
	var right_center := Vector2(size.x * 0.84, size.y * 0.78)
	_draw_stick(left_center, radius, left_value, "FLIGHT")
	_draw_stick(right_center, radius, right_value, "SPEED")

func _draw_stick(center: Vector2, radius: float, value: Vector2, caption: String) -> void:
	draw_circle(center, radius, Color(0.025, 0.07, 0.13, 0.38))
	draw_arc(center, radius, 0.0, TAU, 64, Color(0.55, 0.82, 1.0, 0.8), 3.0, true)
	draw_arc(center, radius * 0.65, 0.0, TAU, 48, Color(0.55, 0.82, 1.0, 0.25), 1.0, true)
	var knob := center + value * radius * 0.65
	draw_circle(knob, radius * 0.34, Color(0.24, 0.65, 0.95, 0.78))
	draw_arc(knob, radius * 0.34, 0.0, TAU, 48, Color(0.82, 0.94, 1.0, 0.95), 2.0, true)
	draw_string(ThemeDB.fallback_font, center + Vector2(-radius * 0.4, radius + 22.0), caption, HORIZONTAL_ALIGNMENT_CENTER, radius * 0.8, 14, Color(0.82, 0.92, 1.0, 0.9))
