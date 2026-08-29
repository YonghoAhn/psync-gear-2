extends Control
class_name RelicSlotRail

@export var slot_count := 8
var displayed_slot_count := 0
var relics: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	displayed_slot_count = slot_count
	queue_redraw()

func set_relics(value: Array) -> void:
	relics = value.duplicate(true)
	queue_redraw()

func _draw() -> void:
	# Cyan under-print and magenta over-print make the rail feel physically misregistered.
	_draw_box(Rect2(5, 5, size.x - 5, size.y - 5), Color(ArtDirection.CYAN.r, ArtDirection.CYAN.g, ArtDirection.CYAN.b, 0.28), ArtDirection.CYAN, 2, 1)
	_draw_box(Rect2(Vector2.ZERO, size - Vector2(5, 5)), Color(ArtDirection.INK.r, ArtDirection.INK.g, ArtDirection.INK.b, 0.94), ArtDirection.MAGENTA, 3, 1)
	draw_rect(Rect2(0, 0, 168, 7), ArtDirection.MAGENTA)
	draw_string(ThemeDB.fallback_font, Vector2(17, 25), "RELICS // %02d" % relics.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ArtDirection.PAPER)
	var slot_size := 38.0
	var gap := 11.0
	var total := slot_count * slot_size + maxi(0, slot_count - 1) * gap
	var start_x := maxf(142.0, (size.x - total) * 0.5)
	for index in range(slot_count):
		var y := 12.0 + (-2.0 if index % 2 else 1.0)
		var rect := Rect2(start_x + index * (slot_size + gap), y, slot_size, slot_size)
		draw_rect(Rect2(rect.position + Vector2(3, 3), rect.size), ArtDirection.CYAN, true)
		_draw_box(rect, Color("28172f"), ArtDirection.PAPER_DIM, 2, 1)
		var center := rect.get_center()
		if index < relics.size():
			var relic: Dictionary = relics[index]
			var color: Color = relic.get("color", ArtDirection.YELLOW)
			draw_circle(center, 12.0, ArtDirection.VOID)
			draw_circle(center, 9.0, color)
			draw_string(ThemeDB.fallback_font, center + Vector2(-7, 5), String(relic.get("icon", "R")).left(2), HORIZONTAL_ALIGNMENT_CENTER, 14, 9, ArtDirection.VOID)
		else:
			draw_line(center + Vector2(-8, -8), center + Vector2(8, 8), Color("745b7c"), 3.0)
			draw_line(center + Vector2(8, -8), center + Vector2(-8, 8), Color("745b7c"), 3.0)
			if index % 3 == 0:
				draw_rect(Rect2(rect.position + Vector2(4, 4), Vector2(8, 3)), ArtDirection.YELLOW)

func _draw_box(rect: Rect2, fill: Color, border: Color, border_width: int, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	draw_style_box(style, rect)