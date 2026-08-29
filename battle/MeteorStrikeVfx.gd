extends Node2D
class_name MeteorStrikeVfx

var age := 0.0
var charge_duration := 3.4
var duration := 4.5
var radius := 170.0

func setup(at: Vector2, size: float, windup: float) -> void:
	global_position = at
	radius = maxf(120.0, size)
	charge_duration = maxf(1.6, windup)
	duration = charge_duration + 0.8

func _process(delta: float) -> void:
	age += delta
	queue_redraw()
	if age >= duration:
		queue_free()

func _draw() -> void:
	if age < charge_duration:
		_draw_descent(clampf(age / charge_duration, 0.0, 1.0))
	else:
		_draw_detonation(clampf((age - charge_duration) / (duration - charge_duration), 0.0, 1.0))

func _draw_descent(t: float) -> void:
	var pulse := 0.78 + sin(age * 18.0) * 0.12
	draw_circle(Vector2.ZERO, radius * (0.12 + t * 0.16), Color(ArtDirection.YELLOW.r, ArtDirection.YELLOW.g, ArtDirection.YELLOW.b, 0.08 + t * 0.12))
	for index in range(20):
		var a0 := -PI * 0.5 + float(index) / 20.0 * TAU
		var a1 := a0 + TAU / 20.0 * 0.63
		var active := float(index) / 20.0 <= t
		draw_arc(Vector2.ZERO, radius * pulse, a0, a1, 4, ArtDirection.YELLOW if active else ArtDirection.CYAN, 5.0 if active else 3.0, false)
	for index in range(8):
		var angle := float(index) / 8.0 * TAU + age * 0.35
		var outer := Vector2.from_angle(angle) * radius * (0.98 - t * 0.16)
		draw_line(outer, outer * 0.66, Color(ArtDirection.CYAN.r, ArtDirection.CYAN.g, ArtDirection.CYAN.b, 0.7), 3.0, false)

	var start := Vector2(-radius * 0.92, -minf(620.0, radius * 3.5))
	var end := Vector2.ZERO
	var fall := t * t * (3.0 - 2.0 * t)
	var meteor_position := start.lerp(end, fall)
	var tail := meteor_position - Vector2(-0.92, -1.0).normalized() * radius * (0.9 + t)
	draw_line(tail + Vector2(7, 5), meteor_position + Vector2(7, 5), Color(ArtDirection.CYAN.r, ArtDirection.CYAN.g, ArtDirection.CYAN.b, 0.55), 28.0, false)
	draw_line(tail, meteor_position, ArtDirection.VOID, 32.0, false)
	draw_line(tail, meteor_position, ArtDirection.YELLOW, 17.0, false)
	draw_circle(meteor_position + Vector2(5, 4), 24.0 + t * 18.0, ArtDirection.CYAN)
	draw_circle(meteor_position, 24.0 + t * 18.0, ArtDirection.VOID)
	draw_circle(meteor_position, 16.0 + t * 13.0, ArtDirection.PAPER)
	draw_circle(meteor_position, 8.0 + t * 7.0, ArtDirection.YELLOW)

func _draw_detonation(t: float) -> void:
	var fade := 1.0 - t
	var blast_radius := radius * (0.35 + t * 1.15)
	for ring_index in range(3):
		var ring_radius := blast_radius * (1.0 - ring_index * 0.18)
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 48, Color(ArtDirection.CYAN.r, ArtDirection.CYAN.g, ArtDirection.CYAN.b, fade * (0.9 - ring_index * 0.2)), 10.0 - ring_index * 2.0, false)
	var star := PackedVector2Array()
	for index in range(32):
		var angle := float(index) / 32.0 * TAU
		var spike := blast_radius * (1.0 if index % 2 == 0 else 0.28)
		star.append(Vector2.from_angle(angle) * spike)
	draw_colored_polygon(star, Color(ArtDirection.YELLOW.r, ArtDirection.YELLOW.g, ArtDirection.YELLOW.b, fade * 0.55))
	draw_circle(Vector2.ZERO, blast_radius * 0.32, Color(ArtDirection.PAPER.r, ArtDirection.PAPER.g, ArtDirection.PAPER.b, fade * 0.92))
	for index in range(14):
		var angle := float(index) / 14.0 * TAU + 0.11
		var inner := Vector2.from_angle(angle) * blast_radius * 0.52
		var outer := Vector2.from_angle(angle) * blast_radius * 1.18
		draw_line(inner, outer, Color(ArtDirection.YELLOW.r, ArtDirection.YELLOW.g, ArtDirection.YELLOW.b, fade), 5.0, false)
