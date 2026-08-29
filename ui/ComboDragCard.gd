extends Button
class_name ComboDragCard

signal card_dropped(card_id: StringName, target_combo_index: int, target_card_index: int)

var card_id: StringName
var source_combo_index := -1
var source_card_index := -1
var drop_highlight := false

func configure(id: StringName, combo_index: int, card_index: int, label_text: String) -> void:
	card_id = id
	source_combo_index = combo_index
	source_card_index = card_index
	text = label_text
	tooltip_text = "드래그해서 콤보와 발동 순서를 변경"
	custom_minimum_size.y = 44
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview := PanelContainer.new()
	preview.custom_minimum_size = Vector2(maxf(170.0, size.x), 42)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", ArtDirection.PAPER)
	preview.add_child(label)
	var style := StyleBoxFlat.new()
	style.bg_color = ArtDirection.INK
	style.border_color = ArtDirection.YELLOW
	style.set_border_width_all(3)
	preview.add_theme_stylebox_override("panel", style)
	set_drag_preview(preview)
	return {
		"type": "combo_card",
		"card_id": card_id,
		"source_combo_index": source_combo_index,
		"source_card_index": source_card_index,
	}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var valid: bool = data is Dictionary and data.get("type", "") == "combo_card"
	if drop_highlight != valid:
		drop_highlight = valid
		queue_redraw()
	return valid

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	drop_highlight = false
	queue_redraw()
	card_dropped.emit(StringName(data.get("card_id", "")), source_combo_index, source_card_index)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and drop_highlight:
		drop_highlight = false
		queue_redraw()

func _draw() -> void:
	if drop_highlight:
		draw_rect(Rect2(Vector2.ZERO, size), ArtDirection.YELLOW, false, 4.0)
