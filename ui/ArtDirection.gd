extends RefCounted
class_name ArtDirection

## Shared screen-print / Y2K zine art direction.
## Keep gameplay readability by reserving yellow for focus and cyan for friendly utility.

const VOID := Color("090711")
const INK := Color("17101f")
const PAPER := Color("fff0d7")
const PAPER_DIM := Color("cdbcae")
const MAGENTA := Color("f20b88")
const PINK := Color("ff5ba7")
const VIOLET := Color("6735d9")
const CYAN := Color("08c8cf")
const YELLOW := Color("f4df19")
const DANGER := Color("ff355d")
const MUTED := Color("6f607d")

static func family_color(family: StringName) -> Color:
	match family:
		&"fire": return MAGENTA
		&"water": return CYAN
		&"poison": return Color("91d63b")
		&"sword": return PAPER
		&"spear": return YELLOW
		&"blunt": return VIOLET
		_: return PAPER

static func panel_style(fill := INK, border := MAGENTA, width := 3, radius := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style

static func create_theme() -> Theme:
	var theme := Theme.new()
	theme.set_color("font_color", "Label", PAPER)
	theme.set_color("font_shadow_color", "Label", Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, 0.55))
	theme.set_constant("shadow_offset_x", "Label", 2)
	theme.set_constant("shadow_offset_y", "Label", 2)
	theme.set_font_size("font_size", "Label", 16)

	var normal := panel_style(Color("201529"), Color("5e3b6e"), 2, 2)
	var hover := panel_style(Color("33203e"), CYAN, 3, 2)
	var pressed := panel_style(MAGENTA, VOID, 3, 2)
	var disabled := panel_style(Color("17131d"), Color("44384b"), 2, 2)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = YELLOW
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(2)
	theme.set_stylebox("normal", "Button", normal)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_stylebox("disabled", "Button", disabled)
	theme.set_stylebox("focus", "Button", focus)
	theme.set_color("font_color", "Button", PAPER)
	theme.set_color("font_hover_color", "Button", CYAN)
	theme.set_color("font_pressed_color", "Button", VOID)
	theme.set_color("font_disabled_color", "Button", MUTED)
	theme.set_font_size("font_size", "Button", 18)
	theme.set_constant("outline_size", "Button", 2)
	theme.set_color("font_outline_color", "Button", VOID)

	var separator := StyleBoxFlat.new()
	separator.bg_color = MAGENTA
	separator.content_margin_top = 2.0
	separator.content_margin_bottom = 2.0
	theme.set_stylebox("separator", "HSeparator", separator)
	theme.set_constant("separation", "VBoxContainer", 14)
	theme.set_constant("separation", "HBoxContainer", 10)

	var slider_bg := panel_style(Color("201529"), Color("5e3b6e"), 2, 0)
	slider_bg.content_margin_top = 5.0
	slider_bg.content_margin_bottom = 5.0
	var slider_fill := panel_style(MAGENTA, YELLOW, 1, 0)
	theme.set_stylebox("slider", "HSlider", slider_bg)
	theme.set_stylebox("grabber_area", "HSlider", slider_fill)
	theme.set_stylebox("grabber_area_highlight", "HSlider", slider_fill)

	return theme

