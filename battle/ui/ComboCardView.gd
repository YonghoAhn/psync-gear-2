extends Control
class_name ComboCardView

enum DisplayState { QUEUED, ACTIVE, USED }

var card: CardInstance
var order := 0
var display_state := DisplayState.QUEUED
var pulse_time := 0.0
var family_color := ArtDirection.PAPER

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size * 0.5
	set_process(true)

func configure(instance: CardInstance, position_in_combo: int) -> void:
	card = instance
	order = position_in_combo
	if card:
		family_color = ArtDirection.family_color(card.family_id)
	queue_redraw()

func set_display_state(next_state: DisplayState) -> void:
	display_state = next_state
	queue_redraw()

func _process(delta: float) -> void:
	pulse_time += delta
	if display_state == DisplayState.ACTIVE:
		queue_redraw()

func _draw() -> void:
	var active_pulse := (sin(pulse_time * 14.0) + 1.0) * 0.5 if display_state == DisplayState.ACTIVE else 0.0
	var alpha := 0.42 if display_state == DisplayState.USED else 1.0
	var ink := Color(ArtDirection.INK.r, ArtDirection.INK.g, ArtDirection.INK.b, alpha)
	var paper := Color(ArtDirection.PAPER.r, ArtDirection.PAPER.g, ArtDirection.PAPER.b, alpha)
	var accent := Color(family_color.r, family_color.g, family_color.b, alpha)
	# Two offset layers mimic cheap print registration and keep cards readable in motion.
	draw_rect(Rect2(5, 5, size.x - 2, size.y - 2), Color(ArtDirection.CYAN.r, ArtDirection.CYAN.g, ArtDirection.CYAN.b, 0.45 * alpha), true)
	draw_rect(Rect2(-3, 2, size.x, size.y), Color(ArtDirection.MAGENTA.r, ArtDirection.MAGENTA.g, ArtDirection.MAGENTA.b, 0.35 * alpha), true)
	var style := StyleBoxFlat.new()
	style.bg_color = ink
	style.border_color = ArtDirection.YELLOW if display_state == DisplayState.ACTIVE else accent
	style.set_border_width_all(4 if display_state == DisplayState.ACTIVE else 2)
	style.set_corner_radius_all(1)
	draw_style_box(style, Rect2(Vector2.ZERO, size))
	draw_rect(Rect2(4, 4, size.x - 8, 6), accent)
	if display_state == DisplayState.ACTIVE:
		var tab_width := 22.0 + active_pulse * 8.0
		draw_rect(Rect2(size.x - tab_width, -5, tab_width, 9), ArtDirection.YELLOW)
		draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(14, 0), Vector2(0, 14)]), ArtDirection.CYAN)
	draw_circle(Vector2(14, 19), 10.0, ArtDirection.VOID)
	draw_string(ThemeDB.fallback_font, Vector2(9, 23), str(order + 1), HORIZONTAL_ALIGNMENT_CENTER, 10, 11, ArtDirection.YELLOW)
	# One crude family glyph replaces detailed card illustration.
	var glyph_center := Vector2(size.x * 0.5, 38)
	if card and card.family_id == &"water":
		draw_arc(glyph_center, 10, 0.2, PI * 1.75, 8, accent, 4.0)
	elif card and card.family_id == &"fire":
		draw_colored_polygon(PackedVector2Array([glyph_center + Vector2(0, -12), glyph_center + Vector2(9, 9), glyph_center, Vector2(glyph_center.x - 9, glyph_center.y + 9)]), accent)
	else:
		draw_line(glyph_center + Vector2(-9, 8), glyph_center + Vector2(9, -8), accent, 5.0)
	var name := card.display_name if card else "EMPTY"
	if name.length() > 7:
		name = name.left(7)
	draw_string(ThemeDB.fallback_font, Vector2(5, 67), name, HORIZONTAL_ALIGNMENT_CENTER, size.x - 10, 13, paper)
	var cooldown := card.card_def.execution_interval if card and card.card_def else 0.0
	var groups: Array[String] = card.card_def.targeting_labels() if card and card.card_def else []
	var group_text := " · ".join(groups.slice(0, 2))
	draw_rect(Rect2(5, size.y - 22, size.x - 10, 17), Color("2b1934"))
	var timing_color := ArtDirection.YELLOW if cooldown >= 3.0 else accent
	draw_string(ThemeDB.fallback_font, Vector2(7, size.y - 9), "%.1fs · %s" % [cooldown, group_text], HORIZONTAL_ALIGNMENT_LEFT, size.x - 12, 8, timing_color)
	if cooldown >= 3.0:
		draw_rect(Rect2(size.x - 28, 12, 24, 12), ArtDirection.MAGENTA)
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 27, 22), "HEAVY", HORIZONTAL_ALIGNMENT_CENTER, 22, 7, ArtDirection.PAPER)
	if display_state == DisplayState.USED:
		draw_line(Vector2(8, 16), Vector2(size.x - 8, size.y - 16), ArtDirection.MAGENTA, 5.0)
		draw_line(Vector2(size.x - 8, 16), Vector2(8, size.y - 16), ArtDirection.MAGENTA, 5.0)