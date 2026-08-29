extends Control
class_name ConsumableSlotPanel

var snapshot: Array = []
var selected_index := 0
var pulse_time := 0.0
var failed_slot := -1
var failed_left := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func apply_snapshot(items: Array, selected: int) -> void:
	snapshot = items.duplicate(true)
	selected_index = clampi(selected, 0, 2)
	queue_redraw()

func flash_unavailable(slot_index: int) -> void:
	failed_slot = slot_index
	failed_left = 0.32
	queue_redraw()

func _process(delta: float) -> void:
	pulse_time += delta
	failed_left = maxf(0.0, failed_left - delta)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(6, 7, size.x - 6, size.y - 7), Color(ArtDirection.CYAN.r, ArtDirection.CYAN.g, ArtDirection.CYAN.b, 0.35), true)
	_draw_box(Rect2(Vector2.ZERO, size - Vector2(6, 7)), Color(ArtDirection.INK.r, ArtDirection.INK.g, ArtDirection.INK.b, 0.96), ArtDirection.MAGENTA, 3, 1)
	draw_rect(Rect2(0, 0, size.x - 6, 7), ArtDirection.MAGENTA)
	draw_string(ThemeDB.fallback_font, Vector2(11, 24), "ITEMS", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, ArtDirection.PAPER)
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 36, 23), "03", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ArtDirection.YELLOW)
	for index in range(3):
		_draw_slot(index, Rect2(10, 34 + index * 86, size.x - 26, 76))
	draw_string(ThemeDB.fallback_font, Vector2(8, size.y - 8), "WHEEL  /  RMB", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, ArtDirection.CYAN)

func _draw_slot(index: int, base_rect: Rect2) -> void:
	var selected := index == selected_index
	var pulse := (sin(pulse_time * 7.0) + 1.0) * 0.5
	var kick := 2.0 + pulse * 2.0 if selected else 0.0
	var rect := Rect2(base_rect.position - Vector2(kick, kick), base_rect.size + Vector2(kick * 2.0, kick * 2.0))
	var item: Dictionary = snapshot[index] if index < snapshot.size() else {"name": "EMPTY", "kind": "", "count": 0}
	var count := int(item.get("count", 0))
	var disabled := count <= 0
	var fill := Color("321b39") if selected else Color("211629")
	var border := ArtDirection.YELLOW if selected else Color("70527c")
	if failed_left > 0.0 and index == failed_slot:
		border = ArtDirection.DANGER
		fill = Color("53172e")
	# Offset cyan print is deliberately visible only on the focused card.
	if selected:
		draw_rect(Rect2(rect.position + Vector2(5, 5), rect.size), ArtDirection.CYAN, true)
	_draw_box(rect, fill, border, 4 if selected else 2, 1)
	if selected:
		draw_colored_polygon(PackedVector2Array([
			Vector2(rect.position.x - 10 - pulse * 3, rect.get_center().y),
			Vector2(rect.position.x - 2, rect.get_center().y - 8),
			Vector2(rect.position.x - 2, rect.get_center().y + 8),
		]), ArtDirection.YELLOW)
		draw_rect(Rect2(rect.position + Vector2(3, 3), Vector2(26, 4)), ArtDirection.MAGENTA)
	var content_color := Color("6d5b70") if disabled else ArtDirection.PAPER
	_draw_bottle(rect.position + Vector2(12, 14), String(item.get("kind", "")), content_color)
	draw_circle(rect.position + Vector2(12, 12), 9.0, ArtDirection.VOID)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(7, 16), str(index + 1), HORIZONTAL_ALIGNMENT_CENTER, 10, 11, ArtDirection.YELLOW if selected else ArtDirection.PAPER_DIM)
	var item_name := String(item.get("name", "EMPTY")).replace(" 드링크", "").replace(" 엘릭서", "").replace(" 토닉", "")
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(5, 62), item_name, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 10, 12, content_color)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(rect.size.x - 25, 17), "×%d" % count, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ArtDirection.DANGER if disabled else ArtDirection.YELLOW)

func _draw_bottle(at: Vector2, kind: String, color: Color) -> void:
	var tint := ArtDirection.MAGENTA if kind == "heal" else ArtDirection.CYAN if kind == "defense" else ArtDirection.YELLOW if kind == "haste" else color
	var points := PackedVector2Array([
		at + Vector2(20, 8), at + Vector2(34, 8), at + Vector2(38, 14),
		at + Vector2(36, 38), at + Vector2(18, 38), at + Vector2(16, 14)
	])
	draw_colored_polygon(points, ArtDirection.VOID)
	var inner := PackedVector2Array([
		at + Vector2(22, 11), at + Vector2(32, 11), at + Vector2(34, 16),
		at + Vector2(33, 35), at + Vector2(21, 35), at + Vector2(20, 16)
	])
	draw_colored_polygon(inner, tint)
	draw_rect(Rect2(at + Vector2(21, 3), Vector2(12, 7)), color)
	draw_line(at + Vector2(21, 27), at + Vector2(33, 22), ArtDirection.PAPER, 2.0)

func _draw_box(rect: Rect2, fill: Color, border: Color, border_width: int, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	draw_style_box(style, rect)