extends Node2D
class_name SpawnWarningMarker

var duration := 1.0
var age := 0.0
var tint := ArtDirection.MAGENTA
var boss := false

func setup(at: Vector2, role: EnemyDef.Role, is_boss := false, warning_duration := 1.0) -> void:
	global_position = at
	boss = is_boss
	duration = warning_duration
	tint = ArtDirection.DANGER if boss else [ArtDirection.MAGENTA, ArtDirection.YELLOW, ArtDirection.CYAN, ArtDirection.VIOLET, ArtDirection.PINK, ArtDirection.DANGER, ArtDirection.YELLOW, ArtDirection.PAPER_DIM][role]

func _ready() -> void:
	add_to_group(&"spawn_warning")
	queue_redraw()

func _process(delta: float) -> void:
	age += delta
	queue_redraw()
	if age >= duration:
		queue_free()

func _draw() -> void:
	var progress := clampf(age / duration, 0.0, 1.0)
	var pulse := (sin(age * 28.0) + 1.0) * 0.5
	var radius := (50.0 if boss else 34.0) + pulse * 4.0
	# Rough striped fill and a cyan registration shadow.
	for i in range(-5, 6):
		var y := float(i) * radius * 0.16
		var half_width := sqrt(maxf(0.0, radius * radius - y * y))
		draw_line(Vector2(-half_width, y) + Vector2(4, 4), Vector2(half_width, y) + Vector2(4, 4), Color(ArtDirection.CYAN.r, ArtDirection.CYAN.g, ArtDirection.CYAN.b, 0.12), 4.0, false)
		draw_line(Vector2(-half_width, y), Vector2(half_width, y), Color(tint.r, tint.g, tint.b, 0.10), 3.0, false)
	var jagged := PackedVector2Array()
	for i in range(17):
		var a := float(i) / 16.0 * TAU
		var jag := radius + (4.0 if i % 2 else -3.0)
		jagged.append(Vector2.from_angle(a) * jag)
	jagged.append(jagged[0])
	var shadow := PackedVector2Array()
	for point in jagged:
		shadow.append(point + Vector2(5, 4))
	draw_polyline(shadow, Color(ArtDirection.CYAN.r, ArtDirection.CYAN.g, ArtDirection.CYAN.b, 0.62), 5.0, false)
	draw_polyline(jagged, ArtDirection.VOID, 9.0, false)
	draw_polyline(jagged, tint, 5.0, false)
	# Segmented countdown is more readable than a smooth radial sweep.
	for index in range(12):
		var active := float(index + 1) / 12.0 <= progress
		var a0 := -PI * 0.5 + float(index) / 12.0 * TAU
		var a1 := a0 + TAU / 12.0 * 0.68
		draw_arc(Vector2.ZERO, radius + 10.0, a0, a1, 3, ArtDirection.YELLOW if active else Color(tint.r, tint.g, tint.b, 0.34), 5.0, false)
	for index in range(4):
		var direction := Vector2.from_angle(index * PI * 0.5)
		draw_line(direction * (radius - 10.0), direction * (radius + 16.0), ArtDirection.PAPER, 3.0, false)
	var label_width := 74.0 if boss else 62.0
	draw_rect(Rect2(-label_width * 0.5 + 3, -7 + 3, label_width, 15), ArtDirection.CYAN)
	draw_rect(Rect2(-label_width * 0.5, -7, label_width, 15), ArtDirection.VOID)
	draw_string(ThemeDB.fallback_font, Vector2(-label_width * 0.5, 4), "BOSS!!" if boss else "SPAWN!", HORIZONTAL_ALIGNMENT_CENTER, label_width, 10, ArtDirection.YELLOW)