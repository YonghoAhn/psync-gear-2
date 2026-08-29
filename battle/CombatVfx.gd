extends Node2D
class_name CombatVfx

enum Kind { SLASH, RING, IMPACT, TELEGRAPH, HEAL, SHIELD, AFTERIMAGE }
enum Side { NEUTRAL, FRIENDLY, HOSTILE }

var kind := Kind.IMPACT
var tint := Color.WHITE
var life := 0.35
var age := 0.0
var radius := 60.0
var direction := Vector2.RIGHT
var width_degrees := 100.0
var side := Side.NEUTRAL

static func create(effect_kind: Kind, at: Vector2, color: Color, size := 60.0, seconds := 0.35, aim := Vector2.RIGHT, arc := 100.0, effect_side := Side.NEUTRAL) -> CombatVfx:
	var effect := CombatVfx.new()
	effect.kind = effect_kind
	effect.position = at
	effect.tint = color
	effect.radius = size
	effect.life = seconds
	effect.direction = aim.normalized() if aim != Vector2.ZERO else Vector2.RIGHT
	effect.width_degrees = arc
	effect.side = effect_side
	return effect

func _process(delta: float) -> void:
	age += delta
	queue_redraw()
	if age >= life:
		queue_free()

func _draw() -> void:
	var t := clampf(age / life, 0.0, 1.0)
	var fade := 1.0 - t
	match kind:
		Kind.SLASH:
			_draw_slash(t, fade)
		Kind.RING, Kind.HEAL, Kind.SHIELD:
			_draw_ring(t, fade)
		Kind.TELEGRAPH:
			_draw_telegraph(t, fade)
		Kind.AFTERIMAGE:
			_draw_afterimage(t, fade)
		_:
			_draw_impact(t, fade)

func _primary() -> Color:
	if side == Side.FRIENDLY:
		return ArtDirection.CYAN
	if side == Side.HOSTILE:
		return ArtDirection.DANGER
	return tint

func _accent() -> Color:
	if side == Side.FRIENDLY:
		return ArtDirection.YELLOW
	if side == Side.HOSTILE:
		return ArtDirection.MAGENTA
	return ArtDirection.YELLOW

func _registration() -> Color:
	if side == Side.FRIENDLY:
		return ArtDirection.PAPER
	if side == Side.HOSTILE:
		return ArtDirection.VOID
	return ArtDirection.CYAN

func _draw_slash(t: float, fade: float) -> void:
	var center := direction.angle()
	var half := deg_to_rad(width_degrees) * 0.5
	var points := PackedVector2Array()
	for i in range(13):
		var ratio := float(i) / 12.0
		var a := lerpf(center - half, center + half, ratio)
		var jitter := 1.0 + (0.035 if i % 2 else -0.025)
		points.append(Vector2.from_angle(a) * radius * (0.58 + t * 0.42) * jitter)
	var offset_points := PackedVector2Array()
	for point in points:
		offset_points.append(point + Vector2(5, 4))
	draw_polyline(offset_points, _alpha(_registration(), 0.58 * fade), 16.0 * fade + 3.0, false)
	draw_polyline(points, _alpha(ArtDirection.VOID, fade), 20.0 * fade + 5.0, false)
	draw_polyline(points, _alpha(_primary(), fade), 13.0 * fade + 3.0, false)
	draw_polyline(points, _alpha(ArtDirection.PAPER if side != Side.HOSTILE else ArtDirection.MAGENTA, fade), 3.0, false)
	for i in range(5):
		var a := center + lerpf(-half, half, float(i) / 4.0)
		var inner := Vector2.from_angle(a) * radius * (0.45 + t * 0.22)
		var outer := Vector2.from_angle(a) * radius * (0.78 + t * 0.38)
		draw_line(inner, outer, _alpha(_accent() if i % 2 else _primary(), fade), 3.0, false)

func _draw_ring(t: float, fade: float) -> void:
	var r := radius * (0.22 + t * 0.78)
	var points := PackedVector2Array()
	for i in range(25):
		var a := float(i) / 24.0 * TAU
		var jag := 1.0 + (0.045 if i % 2 else -0.035)
		points.append(Vector2.from_angle(a) * r * jag)
	points.append(points[0])
	var offset_points := PackedVector2Array()
	for point in points:
		offset_points.append(point + Vector2(4, 3))
	draw_polyline(offset_points, _alpha(_registration(), 0.48 * fade), 10.0 * fade + 2.0, false)
	draw_polyline(points, _alpha(ArtDirection.VOID, fade), 12.0 * fade + 3.0, false)
	draw_polyline(points, _alpha(_primary(), fade), 7.0 * fade + 2.0, false)
	for i in range(8):
		var p := Vector2.from_angle(float(i) / 8.0 * TAU + age * 2.0) * r
		if kind == Kind.HEAL:
			draw_line(p + Vector2(-5, 0), p + Vector2(5, 0), _alpha(_accent(), fade), 3.0)
			draw_line(p + Vector2(0, -5), p + Vector2(0, 5), _alpha(_accent(), fade), 3.0)
		elif kind == Kind.SHIELD:
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -5), p + Vector2(5, 4), p + Vector2(-5, 4)]), _alpha(_primary(), fade))
		else:
			draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), _alpha(_accent(), fade))

func _draw_telegraph(t: float, fade: float) -> void:
	var pulse := 0.55 + sin(age * 22.0) * 0.18
	draw_circle(Vector2.ZERO, radius, _alpha(_primary(), 0.08 + pulse * 0.08), true)
	for i in range(12):
		var a0 := float(i) / 12.0 * TAU
		if i % 2 == 0:
			draw_line(Vector2.from_angle(a0) * radius * 0.22, Vector2.from_angle(a0) * radius, _alpha(_primary(), 0.28), 4.0, false)
	for i in range(16):
		var active := float(i) / 16.0 <= t
		var a0 := -PI * 0.5 + float(i) / 16.0 * TAU
		var a1 := -PI * 0.5 + float(i + 0.72) / 16.0 * TAU
		draw_arc(Vector2.ZERO, radius, a0, a1, 3, _alpha(_accent() if active else _primary(), 0.95), 6.0, false)
	draw_line(Vector2(-radius * 0.30, 0), Vector2(radius * 0.30, 0), _alpha(_registration(), fade), 3.0)
	draw_line(Vector2(0, -radius * 0.30), Vector2(0, radius * 0.30), _alpha(_registration(), fade), 3.0)

func _draw_afterimage(t: float, fade: float) -> void:
	var scale_factor := 1.0 - t * 0.25
	var shape := PackedVector2Array([
		Vector2(-radius, radius * 0.18), Vector2(-radius * 0.35, -radius * 0.78),
		Vector2(radius * 0.25, -radius * 0.55), Vector2(radius * 1.45, 0),
		Vector2(radius * 0.15, radius * 0.62)
	])
	for i in range(shape.size()):
		shape[i] *= scale_factor
	var offset_shape := PackedVector2Array()
	for point in shape:
		offset_shape.append(point + Vector2(7, 4))
	draw_colored_polygon(offset_shape, _alpha(_registration(), 0.38 * fade))
	draw_colored_polygon(shape, _alpha(_primary(), 0.60 * fade))
	draw_polyline(PackedVector2Array([shape[0], shape[1], shape[2], shape[3], shape[4], shape[0]]), _alpha(ArtDirection.VOID, fade), 4.0, false)

func _draw_impact(t: float, fade: float) -> void:
	var r := radius * (0.28 + t * 0.92)
	var star := PackedVector2Array()
	for i in range(20):
		var a := float(i) / 20.0 * TAU
		star.append(Vector2.from_angle(a) * (r if i % 2 == 0 else r * 0.38))
	var shadow := PackedVector2Array()
	for point in star:
		shadow.append(point + Vector2(5, 5))
	draw_colored_polygon(shadow, _alpha(_registration(), 0.45 * fade))
	draw_colored_polygon(star, _alpha(ArtDirection.VOID, 0.90 * fade))
	var inner := PackedVector2Array()
	for point in star:
		inner.append(point * 0.72)
	draw_colored_polygon(inner, _alpha(_primary(), 0.82 * fade))
	draw_circle(Vector2.ZERO, r * 0.16, _alpha(_registration(), fade))
	for i in range(8):
		var a := float(i) / 8.0 * TAU + 0.12
		draw_line(Vector2.from_angle(a) * r * 0.72, Vector2.from_angle(a) * r * 1.12, _alpha(_accent(), fade), 3.0, false)

func _alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, clampf(alpha, 0.0, 1.0))