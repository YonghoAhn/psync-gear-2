extends Control
class_name ZineBackdrop

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), ArtDirection.VOID)
	# Deliberately misregistered blocks and clipped sticker shapes.
	draw_colored_polygon(PackedVector2Array([
		Vector2(size.x * 0.58, 0), Vector2(size.x, 0),
		Vector2(size.x, size.y * 0.37), Vector2(size.x * 0.72, size.y * 0.26)
	]), Color(ArtDirection.MAGENTA.r, ArtDirection.MAGENTA.g, ArtDirection.MAGENTA.b, 0.19))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, size.y * 0.68), Vector2(size.x * 0.42, size.y), Vector2(0, size.y)
	]), Color(ArtDirection.CYAN.r, ArtDirection.CYAN.g, ArtDirection.CYAN.b, 0.12))

	# Coarse halftone fields; no texture filtering or gradients.
	for y in range(0, 10):
		for x in range(0, 18):
			var p := Vector2(size.x - 310 + x * 17, 34 + y * 17)
			var radius := 2.0 if (x + y) % 3 else 3.5
			draw_circle(p, radius, Color(ArtDirection.CYAN.r, ArtDirection.CYAN.g, ArtDirection.CYAN.b, 0.28))
	for y in range(0, 7):
		for x in range(0, 13):
			var p := Vector2(24 + x * 16, size.y - 122 + y * 16)
			draw_rect(Rect2(p, Vector2(4, 4)), Color(ArtDirection.MAGENTA.r, ArtDirection.MAGENTA.g, ArtDirection.MAGENTA.b, 0.30))

	# Acid-yellow registration scribbles.
	var scribble := PackedVector2Array([
		Vector2(size.x * 0.54, 38), Vector2(size.x * 0.62, 86),
		Vector2(size.x * 0.58, 108), Vector2(size.x * 0.70, 148),
		Vector2(size.x * 0.66, 174)
	])
	draw_polyline(scribble, Color(ArtDirection.YELLOW.r, ArtDirection.YELLOW.g, ArtDirection.YELLOW.b, 0.62), 3.0, false)
	for x in range(12, int(size.x), 96):
		draw_line(Vector2(x, size.y - 10), Vector2(x + 34, size.y - 10), Color("3b2149"), 3.0)

