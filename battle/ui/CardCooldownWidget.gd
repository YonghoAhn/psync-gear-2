extends Control
class_name CardCooldownWidget

var snapshots: Array[Dictionary] = []
var pulse := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()

func apply_snapshots(value: Array[Dictionary]) -> void:
	snapshots = value
	queue_redraw()

func apply_snapshot(value: Dictionary) -> void:
	snapshots = [] if value.is_empty() else [value]
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _draw() -> void:
	var panel := Rect2(Vector2.ZERO, size)
	draw_rect(Rect2(panel.position + Vector2(5, 5), panel.size), ArtDirection.CYAN)
	draw_rect(panel, ArtDirection.VOID)
	draw_rect(panel.grow(-3.0), Color(ArtDirection.INK.r, ArtDirection.INK.g, ArtDirection.INK.b, 0.96))
	_draw_text("PARALLEL COMBO // LIVE TIMELINES", Vector2(13, 17), 11, ArtDirection.YELLOW)

	if snapshots.is_empty():
		_draw_text("A / B / C  SYNC READY", Vector2(13, 51), 18, ArtDirection.CYAN)
		return

	var row_height := 24.0
	for row in range(mini(3, snapshots.size())):
		var snapshot := snapshots[row]
		var y := 23.0 + row * row_height
		var card := snapshot["card"] as CardInstance
		var next_card := snapshot.get("next_card") as CardInstance
		var remaining: float = snapshot.get("remaining", 0.0)
		var duration: float = maxf(0.02, snapshot.get("duration", 0.02))
		var ratio := clampf(remaining / duration, 0.0, 1.0)
		var heavy := duration >= 2.8
		var accent := ArtDirection.YELLOW if heavy else ArtDirection.CYAN
		var lane_label: String = snapshot.get("lane_label", ComboCardRail.combo_label(row))

		draw_rect(Rect2(10, y, 28, 20), accent)
		_draw_text(lane_label, Vector2(19, y + 15), 13, ArtDirection.VOID)
		var current_name := card.display_name if card else "EMPTY"
		var next_name := next_card.display_name if next_card else current_name
		_draw_text(current_name.left(12), Vector2(47, y + 15), 13, ArtDirection.PAPER)
		_draw_text("▶ %s" % next_name.left(9), Vector2(184, y + 15), 10, ArtDirection.PAPER_DIM)
		_draw_text("%03.1fs" % remaining, Vector2(326, y + 16), 17, accent)

		var bar := Rect2(394, y + 5, size.x - 407, 11)
		draw_rect(bar, ArtDirection.VOID)
		var segments := 16
		for index in range(segments):
			var gap := 2.0
			var segment_width := (bar.size.x - gap * (segments - 1)) / segments
			var rect := Rect2(bar.position + Vector2(index * (segment_width + gap), 1), Vector2(segment_width, bar.size.y - 2))
			var active := float(index + 1) / segments <= ratio
			var color := accent if active else Color(0.18, 0.16, 0.22, 0.85)
			if active and index == int(pulse * 12.0) % segments:
				color = ArtDirection.PAPER
			draw_rect(rect, color)

func _draw_text(value: String, at: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)