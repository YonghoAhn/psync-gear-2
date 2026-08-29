extends CanvasLayer
class_name BattleHud

var root_control: Control
var relic_rail: RelicSlotRail
var consumable_panel: ConsumableSlotPanel
var combo_rail: ComboCardRail
var cooldown_widget: CardCooldownWidget
var hp_bar: ProgressBar
var hp_label: Label
var xp_bar: ProgressBar
var xp_label: Label
var timer_label: Label
var objective_label: Label
var player: BattlePlayer

func _ready() -> void:
	layer = 20
	_build()

func _build() -> void:
	root_control = Control.new()
	root_control.name = "HudSafeArea"
	root_control.position = Vector2.ZERO
	root_control.size = Vector2(1280, 720)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.theme = ArtDirection.create_theme()
	add_child(root_control)

	relic_rail = RelicSlotRail.new()
	relic_rail.name = "RelicSlotRail"
	relic_rail.position = Vector2(42, 12)
	relic_rail.size = Vector2(1042, 60)
	root_control.add_child(relic_rail)

	consumable_panel = ConsumableSlotPanel.new()
	consumable_panel.name = "ConsumableSlotPanel"
	consumable_panel.position = Vector2(1158, 190)
	consumable_panel.size = Vector2(108, 320)
	root_control.add_child(consumable_panel)
	consumable_panel.visible = false

	combo_rail = ComboCardRail.new()
	combo_rail.name = "ComboCardRail"
	combo_rail.position = Vector2(100, 548)
	combo_rail.size = Vector2(1080, 164)
	root_control.add_child(combo_rail)

	cooldown_widget = CardCooldownWidget.new()
	cooldown_widget.name = "CardCooldownWidget"
	cooldown_widget.position = Vector2(330, 462)
	cooldown_widget.size = Vector2(620, 94)
	cooldown_widget.visible = false
	root_control.add_child(cooldown_widget)

	hp_bar = ProgressBar.new()
	hp_bar.name = "PlayerHealthBar"
	hp_bar.position = Vector2(438, 82)
	hp_bar.size = Vector2(404, 26)
	hp_bar.show_percentage = false
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = ArtDirection.INK
	background.border_color = ArtDirection.CYAN
	background.set_border_width_all(3)
	background.set_corner_radius_all(1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = ArtDirection.MAGENTA
	fill.border_color = ArtDirection.YELLOW
	fill.set_border_width_all(1)
	fill.set_corner_radius_all(0)
	hp_bar.add_theme_stylebox_override("background", background)
	hp_bar.add_theme_stylebox_override("fill", fill)
	root_control.add_child(hp_bar)

	hp_label = _label(Vector2(438, 82), Vector2(404, 26), "HP", 14, HORIZONTAL_ALIGNMENT_CENTER)
	timer_label = _label(Vector2(24, 82), Vector2(180, 26), "TIME", 17, HORIZONTAL_ALIGNMENT_LEFT)
	objective_label = _label(Vector2(1050, 82), Vector2(190, 26), "처치 0", 16, HORIZONTAL_ALIGNMENT_RIGHT)
	timer_label.add_theme_color_override("font_color", ArtDirection.CYAN)
	objective_label.add_theme_color_override("font_color", ArtDirection.YELLOW)

	xp_bar = ProgressBar.new()
	xp_bar.name = "SurvivorExperienceBar"
	xp_bar.position = Vector2(438, 114)
	xp_bar.size = Vector2(404, 16)
	xp_bar.show_percentage = false
	xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var xp_background := StyleBoxFlat.new()
	xp_background.bg_color = ArtDirection.VOID
	xp_background.border_color = ArtDirection.PAPER_DIM
	xp_background.set_border_width_all(2)
	var xp_fill := StyleBoxFlat.new()
	xp_fill.bg_color = ArtDirection.CYAN
	xp_fill.border_color = ArtDirection.YELLOW
	xp_fill.set_border_width_all(1)
	xp_bar.add_theme_stylebox_override("background", xp_background)
	xp_bar.add_theme_stylebox_override("fill", xp_fill)
	xp_bar.visible = false
	root_control.add_child(xp_bar)
	xp_label = _label(Vector2(438, 111), Vector2(404, 21), "LV 1", 10, HORIZONTAL_ALIGNMENT_CENTER)
	xp_label.visible = false

func setup(battle_player: BattlePlayer, deck: DeckState, cycle: CycleState) -> void:
	player = battle_player
	combo_rail.setup(deck, cycle)
	if player.consumables_enabled:
		if not player.consumable_inventory_changed.is_connected(_on_consumable_inventory_changed):
			player.consumable_inventory_changed.connect(_on_consumable_inventory_changed)
		if not player.consumable_use_failed.is_connected(consumable_panel.flash_unavailable):
			player.consumable_use_failed.connect(consumable_panel.flash_unavailable)
		_on_consumable_inventory_changed(player.get_consumable_snapshot(), player.selected_consumable)
	set_health(player.hp, player.max_hp, player.shield)

func set_health(hp: float, maximum: float, shield: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = hp
	hp_label.text = "HP %.0f / %.0f   SH %.0f" % [hp, maximum, shield]

func set_time(remaining: float) -> void:
	timer_label.text = "TIME  %05.1f" % maxf(0.0, remaining)

func set_objective(kills: int) -> void:
	objective_label.text = "처치  %d" % kills

func set_survivor_progress(level: int, xp: float, next_xp: float, survival_time: float, kills: int) -> void:
	xp_bar.visible = true
	xp_label.visible = true
	xp_bar.max_value = maxf(1.0, next_xp)
	xp_bar.value = xp
	xp_label.text = "LV %d   XP %.0f / %.0f" % [level, xp, next_xp]
	timer_label.text = "SURV  %02d:%02d" % [int(survival_time) / 60, int(survival_time) % 60]
	objective_label.text = "LV %d  ·  처치 %d" % [level, kills]

func set_relics(relics: Array) -> void:
	relic_rail.set_relics(relics)

func show_combo(combo_index: int) -> void:
	combo_rail.show_combo(combo_index, true)

func activate_card(combo_index: int, card_index: int) -> void:
	combo_rail.activate_card(combo_index, card_index)

func set_card_cooldowns(snapshots: Array[Dictionary]) -> void:
	cooldown_widget.apply_snapshots(snapshots)
	combo_rail.apply_cooldowns(snapshots)

func set_card_cooldown(snapshot: Dictionary) -> void:
	cooldown_widget.apply_snapshot(snapshot)

func _on_consumable_inventory_changed(snapshot: Array, selected_index: int) -> void:
	consumable_panel.apply_snapshot(snapshot, selected_index)

func _label(at: Vector2, dimensions: Vector2, text_value: String, font_size: int, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.position = at
	label.size = dimensions
	label.text = text_value
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", ArtDirection.PAPER)
	label.add_theme_color_override("font_outline_color", ArtDirection.VOID)
	label.add_theme_constant_override("outline_size", 3)
	root_control.add_child(label)
	return label
