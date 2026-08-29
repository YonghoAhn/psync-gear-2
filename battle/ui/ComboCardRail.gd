extends Control
class_name ComboCardRail

const GRID_COLUMNS := 4
const GRID_ROWS := 1
const LANES_PER_PAGE := GRID_COLUMNS * GRID_ROWS

var deck: DeckState
var cycle: CycleState
var active_card_indices: Array[int] = []
var lane_flashes: Array[float] = []
var snapshots_by_lane: Dictionary = {}
var pulse_time := 0.0
var current_page := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	set_process(true)
	queue_redraw()


func setup(run_deck: DeckState, run_cycle: CycleState) -> void:
	deck = run_deck
	cycle = run_cycle
	var lane_count := maxi(1, cycle.combos.size() if cycle else 0)
	active_card_indices.resize(lane_count)
	lane_flashes.resize(lane_count)
	active_card_indices.fill(-1)
	lane_flashes.fill(0.0)
	current_page = 0
	queue_redraw()


func apply_cooldowns(snapshots: Array[Dictionary]) -> void:
	snapshots_by_lane.clear()
	for snapshot in snapshots:
		snapshots_by_lane[int(snapshot.get("combo_index", 0))] = snapshot
	queue_redraw()


func show_combo(_combo_index: int, _animate := true) -> void:
	queue_redraw()


func activate_card(combo_index: int, card_index: int) -> void:
	if combo_index < 0 or combo_index >= active_card_indices.size():
		return
	active_card_indices[combo_index] = card_index
	lane_flashes[combo_index] = 0.30
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	var page_count := _page_count()
	if page_count <= 1:
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		current_page = (current_page + 1) % page_count
	elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
		current_page = (current_page - 1 + page_count) % page_count
	else:
		return
	accept_event()
	queue_redraw()


func _process(delta: float) -> void:
	pulse_time += delta
	for index in range(lane_flashes.size()):
		lane_flashes[index] = maxf(0.0, lane_flashes[index] - delta)
	queue_redraw()


func _page_count() -> int:
	var lane_count := maxi(1, cycle.combos.size() if cycle else 0)
	return maxi(1, ceili(float(lane_count) / float(LANES_PER_PAGE)))


func _draw() -> void:
	draw_rect(Rect2(7, 7, size.x - 7, size.y - 7), Color(ArtDirection.CYAN.r, ArtDirection.CYAN.g, ArtDirection.CYAN.b, 0.22))
	draw_rect(Rect2(Vector2.ZERO, size - Vector2(7, 7)), Color(ArtDirection.INK.r, ArtDirection.INK.g, ArtDirection.INK.b, 0.96))
	draw_rect(Rect2(Vector2.ZERO, size - Vector2(7, 7)), ArtDirection.MAGENTA, false, 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(14, 20), "PARALLEL COMBO // CARD POSITION", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ArtDirection.PAPER)

	var page_count := _page_count()
	current_page = clampi(current_page, 0, page_count - 1)
	var lane_count := maxi(1, cycle.combos.size() if cycle else 0)
	var first_lane := current_page * LANES_PER_PAGE
	var visible_count := mini(LANES_PER_PAGE, lane_count - first_lane)
	var page_text := "PAGE %d/%d" % [current_page + 1, page_count]
	if page_count > 1:
		page_text += "  ·  WHEEL TO SCROLL"
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 220, 20), page_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, ArtDirection.YELLOW)

	var gap := 12.0
	var side_margin := 15.0
	var top := 30.0
	var bottom_margin := 12.0
	var rows := ceili(float(visible_count) / float(GRID_COLUMNS))
	var slot_height := (size.y - top - bottom_margin - gap * float(rows - 1)) / float(rows)
	slot_height = minf(slot_height, 122.0)
	var maximum_slot_width := 248.0
	for row in range(rows):
		var row_first := row * GRID_COLUMNS
		var row_count := mini(GRID_COLUMNS, visible_count - row_first)
		var available_width := size.x - side_margin * 2.0 - gap * float(row_count - 1)
		var slot_width := minf(maximum_slot_width, available_width / float(row_count))
		var row_width := slot_width * float(row_count) + gap * float(row_count - 1)
		var row_x := (size.x - row_width) * 0.5
		for column in range(row_count):
			var lane_index := first_lane + row_first + column
			var slot_rect := Rect2(row_x + column * (slot_width + gap), top + row * (slot_height + gap), slot_width, slot_height)
			_draw_combo_slot(lane_index, slot_rect)


func _draw_combo_slot(lane_index: int, rect: Rect2) -> void:
	var lane_colors: Array[Color] = [ArtDirection.CYAN, ArtDirection.YELLOW, ArtDirection.MAGENTA]
	var accent: Color = lane_colors[lane_index % lane_colors.size()]
	var snapshot: Dictionary = snapshots_by_lane.get(lane_index, {})
	var flashing := lane_index < lane_flashes.size() and lane_flashes[lane_index] > 0.0
	var background := Color(0.075, 0.060, 0.095, 0.97)
	if flashing:
		background = Color(accent.r * 0.24, accent.g * 0.24, accent.b * 0.24, 0.98)
	draw_rect(Rect2(rect.position + Vector2(4, 4), rect.size), Color(ArtDirection.VOID.r, ArtDirection.VOID.g, ArtDirection.VOID.b, 0.80))
	draw_rect(rect, background)
	draw_rect(rect, Color(ArtDirection.PAPER_DIM.r, ArtDirection.PAPER_DIM.g, ArtDirection.PAPER_DIM.b, 0.38), false, 2.0)

	var lane_name := "COMBO %s" % combo_label(lane_index)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(10, 20), lane_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ArtDirection.PAPER)

	if snapshot.is_empty():
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(10, 49), "SYNC READY", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, accent)
		_draw_progress_outline(rect.grow(-1.0), 0.0, accent, 4.0)
		return

	var card := snapshot.get("card") as CardInstance
	var next_card := snapshot.get("next_card") as CardInstance
	var remaining: float = snapshot.get("remaining", 0.0)
	var duration: float = maxf(0.02, snapshot.get("duration", 0.02))
	var cooldown_progress := clampf(1.0 - remaining / duration, 0.0, 1.0)
	var active_index := int(snapshot.get("card_index", -1))
	var total_cards := 1
	if cycle != null and lane_index < cycle.combos.size():
		total_cards = maxi(1, cycle.combos[lane_index].card_instance_ids.size())
	var position_progress := card_position_ratio(active_index, total_cards)
	var card_name := card.display_name if card else "EMPTY"
	var next_name := next_card.display_name if next_card else card_name
	var next_prefix := "REPEAT" if next_card == card else "NEXT"

	var inner := rect.grow(-3.0)
	var fill_height := inner.size.y * cooldown_progress
	if fill_height > 0.0:
		var fill_rect := Rect2(inner.position.x, inner.end.y - fill_height, inner.size.x, fill_height)
		draw_rect(fill_rect, Color(accent.r, accent.g, accent.b, 0.19))
		draw_line(Vector2(inner.position.x, fill_rect.position.y), Vector2(inner.end.x, fill_rect.position.y), Color(accent.r, accent.g, accent.b, 0.78), 2.0, false)

	draw_string(ThemeDB.fallback_font, rect.position + Vector2(rect.size.x - 45, 19), "%d/%d" % [active_index + 1, total_cards], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, accent)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(10, 39), "NOW", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, accent)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(10, 59), card_name.left(13), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20, 17, ArtDirection.PAPER)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(10, 78), next_prefix, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, ArtDirection.PAPER_DIM)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(52, 79), next_name.left(11), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 108, 11, Color(ArtDirection.PAPER_DIM.r, ArtDirection.PAPER_DIM.g, ArtDirection.PAPER_DIM.b, 0.88))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(rect.size.x - 48, 79), "%03.1fs" % remaining, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, accent)

	_draw_sequence_dots(lane_index, rect, active_index, accent)
	_draw_progress_outline(rect.grow(-1.0), position_progress, accent, 5.0)


func _draw_sequence_dots(lane_index: int, rect: Rect2, active_index: int, accent: Color) -> void:
	if cycle == null or lane_index >= cycle.combos.size():
		return
	var count := cycle.combos[lane_index].card_instance_ids.size()
	var start_x := rect.position.x + 11.0
	var y := rect.end.y - 9.0
	for index in range(count):
		var color := accent if index == active_index else Color(ArtDirection.PAPER_DIM.r, ArtDirection.PAPER_DIM.g, ArtDirection.PAPER_DIM.b, 0.40)
		draw_rect(Rect2(start_x + index * 11.0, y, 7, 3), color)


static func combo_label(index: int) -> String:
	var number := index + 1
	var result := ""
	while number > 0:
		number -= 1
		result = String.chr(65 + (number % 26)) + result
		number = int(number / 26)
	return result


static func card_position_ratio(card_index: int, total_cards: int) -> float:
	if total_cards <= 0 or card_index < 0:
		return 0.0
	return clampf(float(card_index + 1) / float(total_cards), 0.0, 1.0)


func _draw_progress_outline(rect: Rect2, progress: float, color: Color, width: float) -> void:
	var points := PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
		rect.position,
	])
	var total_length := 0.0
	for index in range(points.size() - 1):
		total_length += points[index].distance_to(points[index + 1])
	var remaining_length := total_length * clampf(progress, 0.0, 1.0)
	var head := points[0]
	for index in range(points.size() - 1):
		if remaining_length <= 0.0:
			break
		var start := points[index]
		var finish := points[index + 1]
		var segment_length := start.distance_to(finish)
		var ratio := minf(1.0, remaining_length / segment_length)
		var partial_end := start.lerp(finish, ratio)
		draw_line(start, partial_end, ArtDirection.VOID, width + 4.0, false)
		draw_line(start, partial_end, color, width, false)
		head = partial_end
		remaining_length -= segment_length
	if progress > 0.0:
		var head_radius := 4.0 + (sin(pulse_time * 14.0) + 1.0) * 1.2
		draw_circle(head, head_radius + 2.0, ArtDirection.VOID)
		draw_circle(head, head_radius, ArtDirection.PAPER)