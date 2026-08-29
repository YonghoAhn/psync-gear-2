extends VBoxContainer
class_name ComboDropZone

signal card_dropped(card_id: StringName, target_combo_index: int, target_card_index: int)

var target_combo_index := -1
var drop_highlight := false

func configure(combo_index: int) -> void:
	target_combo_index = combo_index
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size.y = 64

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var valid: bool = data is Dictionary and data.get("type", "") == "combo_card"
	if drop_highlight != valid:
		drop_highlight = valid
		queue_redraw()
	return valid

func _drop_data(at_position: Vector2, data: Variant) -> void:
	drop_highlight = false
	queue_redraw()
	var insertion_index := _insertion_index(at_position.y)
	card_dropped.emit(StringName(data.get("card_id", "")), target_combo_index, insertion_index)

func _insertion_index(local_y: float) -> int:
	var card_index := 0
	for child in get_children():
		if not child.visible:
			continue
		if local_y < child.position.y + child.size.y * 0.5:
			return card_index
		card_index += 1
	return card_index

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and drop_highlight:
		drop_highlight = false
		queue_redraw()

func _draw() -> void:
	var color := ArtDirection.YELLOW if drop_highlight else Color(ArtDirection.CYAN.r, ArtDirection.CYAN.g, ArtDirection.CYAN.b, 0.22)
	draw_rect(Rect2(Vector2.ZERO, size), Color(ArtDirection.INK.r, ArtDirection.INK.g, ArtDirection.INK.b, 0.28))
	draw_rect(Rect2(Vector2.ZERO, size), color, false, 3.0 if drop_highlight else 1.0)
	if drop_highlight:
		draw_string(ThemeDB.fallback_font, Vector2(10, size.y - 8), "DROP HERE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, ArtDirection.YELLOW)
