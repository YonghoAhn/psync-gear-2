extends Node

var flow := RunFlowController.new()
var unlocks := UnlockProfile.new()
var all_cards: Array[CardDef] = []
var all_characters: Array[CharacterDef] = []
var all_maps: Array[MapDef] = []
var session: RunSession
var deck: DeckState
var cycle: CycleState
var run_map: RunMap
var map_controller := RunMapController.new()
var run_rng: RunRng
var selected_map: MapDef
var selected_character: CharacterDef
var root_control: Control
var pending_node: MapNode
var combo_editor_message := ""
var survivor_arena: BattleArena
var survivor_level_overlay: CanvasLayer
var survivor_reward_claimed := false
const MIN_COMBO_SLOTS := 1
var card_codex_family_filter: StringName = &"all"
var card_codex_rarity_filter := -1
var card_codex_selected_id: StringName = &""


func _ready() -> void:
	all_cards = ContentFactory.cards()
	all_characters = ContentFactory.characters()
	all_maps = ContentFactory.maps()
	_bootstrap_unlocks()
	flow.transition(RunFlowController.State.MAIN_MENU)
	_show_main_menu()


func _bootstrap_unlocks() -> void:
	for map in all_maps:
		unlocks.unlock("maps", map.id)
	for character in all_characters:
		unlocks.unlock("characters", character.id)
	for family in [&"sword", &"fire", &"water"]:
		unlocks.unlock("families", family)


func _clear_screen() -> void:
	for child in get_children():
		child.queue_free()
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.theme = ArtDirection.create_theme()
	add_child(root_control)
	var background := ZineBackdrop.new()
	background.name = "ZineBackdrop"
	root_control.add_child(background)


func _screen_stack(title_text: String, subtitle := "") -> VBoxContainer:
	_clear_screen()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 86)
	margin.add_theme_constant_override("margin_right", 86)
	margin.add_theme_constant_override("margin_top", 54)
	margin.add_theme_constant_override("margin_bottom", 46)
	root_control.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 14)
	margin.add_child(stack)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", ArtDirection.PAPER)
	title.add_theme_color_override("font_shadow_color", ArtDirection.MAGENTA)
	title.add_theme_constant_override("shadow_offset_x", 5)
	title.add_theme_constant_override("shadow_offset_y", 3)
	stack.add_child(title)
	if subtitle != "":
		var sub := Label.new()
		sub.text = subtitle
		sub.add_theme_font_size_override("font_size", 17)
		sub.add_theme_color_override("font_color", ArtDirection.CYAN)
		stack.add_child(sub)
	stack.add_child(HSeparator.new())
	return stack


func _button(text_value: String, callback: Callable, min_width := 430.0) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(min_width, 52)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_constant_override("outline_size", 2)
	button.pressed.connect(callback)
	return button


func _show_main_menu() -> void:
	set_meta(&"starting_survivor_ab", false)
	var stack := _screen_stack("CARBO", "A/B TEST · 노드 런과 무한 생존 런을 동일 카드 시스템으로 비교")
	_add_menu_key_art()
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 70
	stack.add_child(spacer)
	stack.add_child(_button("A · 노드 런", _begin_new_run))
	stack.add_child(_button("B · 무한 생존 실험", _begin_survivor_test))
	var endless := _button("A 확장 · 노드 무한 모드", _begin_endless_run)
	endless.disabled = not unlocks.is_unlocked("endless_maps", &"foundry")
	endless.tooltip_text = "맵 보스를 한 번 처치하면 해금됩니다"
	stack.add_child(endless)
	stack.add_child(_button("카드 도감 · CARD ARCHIVE", _open_card_codex))
	stack.add_child(_button("설정", _show_settings))
	stack.add_child(_button("게임 종료", func(): get_tree().quit()))


func _add_menu_key_art() -> void:
	var frame := Panel.new()
	frame.name = "PilotKeyArt"
	frame.position = Vector2(635, 150)
	frame.size = Vector2(585, 329)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", ArtDirection.panel_style(ArtDirection.INK, ArtDirection.MAGENTA, 4, 1))
	root_control.add_child(frame)
	root_control.move_child(frame, 1)
	var cyan_misprint := ColorRect.new()
	cyan_misprint.position = Vector2(10, 10)
	cyan_misprint.size = frame.size
	cyan_misprint.color = Color(ArtDirection.CYAN.r, ArtDirection.CYAN.g, ArtDirection.CYAN.b, 0.22)
	cyan_misprint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(cyan_misprint)
	var art := TextureRect.new()
	art.position = Vector2(8, 8)
	art.size = frame.size - Vector2(16, 16)
	art.texture = load("res://assets/concept/pilot_v2_2026-08-18/03_y2k_duo_promo.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(art)
	var tag := Label.new()
	tag.text = "PILOT // COMBO RIOT"
	tag.position = Vector2(18, frame.size.y - 39)
	tag.size = Vector2(250, 28)
	tag.add_theme_color_override("font_color", ArtDirection.YELLOW)
	tag.add_theme_font_size_override("font_size", 13)
	frame.add_child(tag)


func _open_card_codex() -> void:
	card_codex_family_filter = &"all"
	card_codex_rarity_filter = -1
	card_codex_selected_id = all_cards[0].id if not all_cards.is_empty() else &""
	_show_card_codex()


func _show_card_codex() -> void:
	_clear_screen()
	var filtered: Array[CardDef] = []
	for card in all_cards:
		if card_codex_family_filter != &"all" and card.family_id != card_codex_family_filter:
			continue
		if card_codex_rarity_filter >= 0 and card.rarity != card_codex_rarity_filter:
			continue
		filtered.append(card)

	var selected: CardDef = null
	for card in filtered:
		if card.id == card_codex_selected_id:
			selected = card
			break
	if selected == null and not filtered.is_empty():
		selected = filtered[0]
		card_codex_selected_id = selected.id

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	root_control.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 9)
	margin.add_child(stack)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	var title := Label.new()
	title.text = "CARD ARCHIVE // 카드 도감"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", ArtDirection.PAPER)
	title.add_theme_color_override("font_shadow_color", ArtDirection.MAGENTA)
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 2)
	header.add_child(title)
	var count_label := Label.new()
	count_label.name = "CardCodexCount"
	count_label.text = "%d / %d CARDS" % [filtered.size(), all_cards.size()]
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 18)
	count_label.add_theme_color_override("font_color", ArtDirection.YELLOW)
	header.add_child(count_label)
	header.add_child(_button("메인 메뉴", _show_main_menu, 150))
	stack.add_child(header)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 10)
	var family_label := Label.new()
	family_label.text = "카드군"
	family_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	family_label.add_theme_color_override("font_color", ArtDirection.CYAN)
	toolbar.add_child(family_label)
	var family_select := OptionButton.new()
	family_select.name = "CardCodexFamilyFilter"
	family_select.custom_minimum_size = Vector2(190, 42)
	var family_ids: Array[StringName] = [&"all", &"sword", &"spear", &"blunt", &"fire", &"water", &"poison"]
	for family_id in family_ids:
		family_select.add_item("전체 카드군" if family_id == &"all" else _family_name(family_id))
	family_select.select(maxi(0, family_ids.find(card_codex_family_filter)))
	family_select.item_selected.connect(_set_codex_family_filter)
	toolbar.add_child(family_select)

	var rarity_label := Label.new()
	rarity_label.text = "희귀도"
	rarity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rarity_label.add_theme_color_override("font_color", ArtDirection.MAGENTA)
	toolbar.add_child(rarity_label)
	var rarity_select := OptionButton.new()
	rarity_select.name = "CardCodexRarityFilter"
	rarity_select.custom_minimum_size = Vector2(170, 42)
	rarity_select.add_item("전체 희귀도")
	for rarity in range(CardDef.Rarity.size()):
		rarity_select.add_item(_rarity_name(rarity as CardDef.Rarity))
	rarity_select.select(card_codex_rarity_filter + 1)
	rarity_select.item_selected.connect(_set_codex_rarity_filter)
	toolbar.add_child(rarity_select)

	var filter_hint := Label.new()
	filter_hint.text = "카드를 선택하면 우측에서 실제 전투 수치와 효과 구성을 확인할 수 있습니다"
	filter_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filter_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	filter_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	filter_hint.add_theme_font_size_override("font_size", 13)
	filter_hint.add_theme_color_override("font_color", ArtDirection.PAPER_DIM)
	toolbar.add_child(filter_hint)
	stack.add_child(toolbar)
	stack.add_child(HSeparator.new())

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	stack.add_child(body)

	var card_scroll := ScrollContainer.new()
	card_scroll.name = "CardCodexScroll"
	card_scroll.custom_minimum_size.x = 790
	card_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	body.add_child(card_scroll)
	var grid := GridContainer.new()
	grid.name = "CardCodexGrid"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	card_scroll.add_child(grid)

	for card in filtered:
		var entry_id := card.id
		var labels: Array[String] = card.targeting_labels()
		var tile := Button.new()
		tile.name = "CardCodexCard_%s" % card.id
		tile.set_meta(&"card_id", card.id)
		tile.text = "%s\n%s · %s · %.1fs\n%s\n%s" % [card.display_name, _family_name(card.family_id), _rarity_name(card.rarity), card.execution_interval, " · ".join(labels), card.description.left(42)]
		tile.tooltip_text = card.description
		tile.custom_minimum_size = Vector2(248, 126)
		tile.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tile.add_theme_font_size_override("font_size", 14)
		tile.add_theme_color_override("font_color", ArtDirection.PAPER)
		tile.add_theme_color_override("font_hover_color", ArtDirection.YELLOW)
		var border_color := ArtDirection.YELLOW if card.id == card_codex_selected_id else _card_family_color(card.family_id)
		tile.add_theme_stylebox_override("normal", ArtDirection.panel_style(Color(0.075, 0.055, 0.095, 0.97), border_color, 2 if card.id == card_codex_selected_id else 1, 1))
		tile.add_theme_stylebox_override("hover", ArtDirection.panel_style(Color(0.12, 0.07, 0.14, 0.99), ArtDirection.YELLOW, 3, 1))
		tile.pressed.connect(func(): _select_codex_card(entry_id))
		grid.add_child(tile)

	if filtered.is_empty():
		var empty := Label.new()
		empty.text = "선택한 조건에 해당하는 카드가 없습니다."
		empty.custom_minimum_size = Vector2(760, 120)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", ArtDirection.PAPER_DIM)
		grid.add_child(empty)

	var detail_panel := PanelContainer.new()
	detail_panel.name = "CardCodexDetail"
	detail_panel.custom_minimum_size.x = 370
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_stylebox_override("panel", ArtDirection.panel_style(ArtDirection.INK, ArtDirection.MAGENTA, 3, 1))
	body.add_child(detail_panel)
	var detail_margin := MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", 16)
	detail_margin.add_theme_constant_override("margin_right", 16)
	detail_margin.add_theme_constant_override("margin_top", 14)
	detail_margin.add_theme_constant_override("margin_bottom", 14)
	detail_panel.add_child(detail_margin)
	var detail_scroll := ScrollContainer.new()
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	detail_margin.add_child(detail_scroll)
	detail_scroll.add_child(_build_card_codex_detail(selected))


func _set_codex_family_filter(index: int) -> void:
	var family_ids: Array[StringName] = [&"all", &"sword", &"spear", &"blunt", &"fire", &"water", &"poison"]
	card_codex_family_filter = family_ids[clampi(index, 0, family_ids.size() - 1)]
	_show_card_codex()


func _set_codex_rarity_filter(index: int) -> void:
	card_codex_rarity_filter = clampi(index - 1, -1, CardDef.Rarity.size() - 1)
	_show_card_codex()


func _select_codex_card(card_id: StringName) -> void:
	card_codex_selected_id = card_id
	_show_card_codex()


func _build_card_codex_detail(card: CardDef) -> Control:
	var detail := VBoxContainer.new()
	detail.custom_minimum_size.x = 332
	detail.add_theme_constant_override("separation", 8)
	if card == null:
		var empty := Label.new()
		empty.text = "표시할 카드가 없습니다."
		detail.add_child(empty)
		return detail

	var title := Label.new()
	title.text = card.display_name
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", _card_family_color(card.family_id))
	detail.add_child(title)
	var identity := Label.new()
	identity.text = "%s · %s · %s" % [_family_name(card.family_id), _rarity_name(card.rarity), _codex_role_name(card.role)]
	identity.add_theme_font_size_override("font_size", 16)
	identity.add_theme_color_override("font_color", ArtDirection.YELLOW)
	detail.add_child(identity)
	var groups := Label.new()
	groups.text = " / ".join(card.targeting_labels())
	groups.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	groups.add_theme_color_override("font_color", ArtDirection.CYAN)
	detail.add_child(groups)
	detail.add_child(HSeparator.new())

	var description := Label.new()
	description.text = card.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 17)
	description.add_theme_color_override("font_color", ArtDirection.PAPER)
	detail.add_child(description)
	detail.add_child(HSeparator.new())

	var profile_title := Label.new()
	profile_title.text = "전투 프로필"
	profile_title.add_theme_font_size_override("font_size", 18)
	profile_title.add_theme_color_override("font_color", ArtDirection.MAGENTA)
	detail.add_child(profile_title)
	var profile := Label.new()
	profile.text = "발동 간격  %.2f초\n효과 선딜레이  %.2f초\n공격 방식  %s\n전달 방식  %s\n대상 우선순위  %s\n위력  %.0f × %d회\n최대 사거리  %.0f\n효과 반경  %.0f\n대상/투사체  %d명 / %d개\n관통  %d · 넉백 %.0f" % [card.execution_interval, card.effect_delay, _codex_pattern_name(card.attack_pattern), _codex_delivery_name(card.delivery_type), _codex_priority_name(card.target_priority), card.base_power, card.hit_count, card.max_range, card.impact_radius, card.target_count, card.projectile_count, card.pierce_count, card.knockback_force]
	profile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profile.add_theme_font_size_override("font_size", 15)
	profile.add_theme_color_override("font_color", ArtDirection.PAPER_DIM)
	detail.add_child(profile)

	if card.status_id != &"" or card.summon_kind != &"" or card.special_rule != &"":
		detail.add_child(HSeparator.new())
		var special_title := Label.new()
		special_title.text = "상태 및 특수 효과"
		special_title.add_theme_font_size_override("font_size", 18)
		special_title.add_theme_color_override("font_color", ArtDirection.YELLOW)
		detail.add_child(special_title)
		var special_lines: Array[String] = []
		if card.status_id != &"":
			special_lines.append("상태: %s · %d스택 · %.1f초" % [_codex_status_name(card.status_id), card.status_stacks, card.status_duration])
		if card.summon_kind != &"":
			special_lines.append("소환/설치: %s · 활성 제한 %d" % [String(card.summon_kind), card.active_limit])
		if card.special_rule != &"":
			special_lines.append("특수 규칙: %s" % String(card.special_rule))
		var special := Label.new()
		special.text = "\n".join(special_lines)
		special.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		special.add_theme_color_override("font_color", ArtDirection.PAPER)
		detail.add_child(special)

	detail.add_child(HSeparator.new())
	var effects_title := Label.new()
	effects_title.text = "실제 효과 구성"
	effects_title.add_theme_font_size_override("font_size", 18)
	effects_title.add_theme_color_override("font_color", ArtDirection.CYAN)
	detail.add_child(effects_title)
	if card.effect_specs.is_empty():
		var no_effect := Label.new()
		no_effect.text = "등록된 효과 스펙 없음"
		no_effect.add_theme_color_override("font_color", ArtDirection.DANGER)
		detail.add_child(no_effect)
	else:
		for effect_index in range(card.effect_specs.size()):
			var effect := card.effect_specs[effect_index] as EffectSpec
			var effect_label := Label.new()
			if effect == null:
				effect_label.text = "%d. 알 수 없는 효과" % (effect_index + 1)
			else:
				effect_label.text = "%d. %s\n   위력 %.0f · 반경 %.0f · 지속 %.1f초\n   태그 %s" % [effect_index + 1, _codex_effect_name(effect.type), effect.power, effect.radius, effect.duration, ", ".join(Array(effect.tags).map(func(tag): return String(tag)))]
			effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			effect_label.add_theme_color_override("font_color", ArtDirection.PAPER_DIM)
			detail.add_child(effect_label)
	return detail


func _card_family_color(family_id: StringName) -> Color:
	return {
		&"sword": ArtDirection.CYAN,
		&"spear": Color(0.55, 0.92, 1.0),
		&"blunt": ArtDirection.YELLOW,
		&"fire": ArtDirection.MAGENTA,
		&"water": Color(0.25, 0.72, 1.0),
		&"poison": Color(0.55, 1.0, 0.45),
	}.get(family_id, ArtDirection.PAPER)


func _codex_role_name(role: CardDef.Role) -> String:
	return ["공격", "방어", "유틸리티"][role]


func _codex_delivery_name(delivery: CardDef.DeliveryType) -> String:
	return ["즉발", "투사체", "설치·소환", "상태이상", "이동"][delivery]


func _codex_pattern_name(pattern: CardDef.AttackPattern) -> String:
	return ["근접 부채꼴", "직선 찌르기", "투사체", "자기중심 범위", "장판", "방어", "이동"][pattern]


func _codex_priority_name(priority: CardDef.TargetPriority) -> String:
	return ["가까운 적", "딸피 우선", "랜덤", "밀집 지역", "자신"][priority]


func _codex_status_name(status_id: StringName) -> String:
	return {
		&"burn": "연소",
		&"poison": "중독",
		&"wet": "젖음",
		&"shock": "감전",
		&"slow": "둔화",
		&"weaken": "약화",
		&"stun": "기절",
		&"corrode": "부식",
	}.get(status_id, String(status_id))


func _codex_effect_name(type: EffectSpec.Type) -> String:
	return [
		"투사체 발사", "범위 피해", "근접 피해", "장판 생성", "설치물 생성",
		"상태이상 부여", "상태이상 제거", "소환수 생성", "체력 회복", "마력 회복",
		"보호막 부여", "이동 효과", "넉백", "버프 부여", "버프 제거", "연쇄 효과",
	][type]


func _begin_new_run() -> void:
	set_meta(&"starting_survivor_ab", false)
	flow.transition(RunFlowController.State.MAP_SELECT)
	_show_map_select(false)


func _begin_endless_run() -> void:
	set_meta(&"starting_survivor_ab", false)
	flow.transition(RunFlowController.State.MAP_SELECT)
	_show_map_select(true)


func _begin_survivor_test() -> void:
	set_meta(&"starting_survivor_ab", true)
	set_meta(&"starting_endless", false)
	flow.transition(RunFlowController.State.MAP_SELECT)
	_show_map_select(false)


func _show_settings() -> void:
	var stack := _screen_stack("설정", "볼륨 설정은 실행 중 즉시 적용됩니다")
	for label_text in ["마스터 볼륨", "효과음 볼륨", "음악 볼륨"]:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = label_text
		label.custom_minimum_size.x = 200
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.value = 80
		slider.custom_minimum_size.x = 420
		row.add_child(label)
		row.add_child(slider)
		stack.add_child(row)
	stack.add_child(_button("돌아가기", _show_main_menu))


func _show_map_select(endless: bool) -> void:
	var survivor_ab := bool(get_meta(&"starting_survivor_ab", false))
	var subtitle := "B안 · 노드 없이 경험치 레벨업으로 계속 진행합니다" if survivor_ab else "클리어한 맵은 노드 무한 모드로 다시 도전할 수 있습니다"
	var stack := _screen_stack("맵 선택", subtitle)
	for map in all_maps:
		var unlocked := unlocks.is_unlocked("maps", map.id)
		var button := _button("%s · %s" % [map.display_name, "다각형 전장" if map.arena_shape == MapDef.ArenaShape.POLYGON else "원형 전장"], func(): _select_map(map, endless))
		button.disabled = not unlocked or (endless and not unlocks.is_unlocked("endless_maps", map.id))
		stack.add_child(button)
	stack.add_child(_button("뒤로", _show_main_menu))


func _select_map(map: MapDef, endless: bool) -> void:
	selected_map = map
	set_meta(&"starting_endless", endless)
	flow.transition(RunFlowController.State.CHARACTER_SELECT)
	_show_character_select()


func _show_character_select() -> void:
	var stack := _screen_stack("캐릭터 선택", "캐릭터마다 스탯, 시작 카드군과 고유 규칙이 다릅니다")
	for character in all_characters:
		var style := "일반형" if character.style == CharacterDef.Style.GENERAL else "기믹형"
		var button := _button("%s  [%s]  HP %.0f · 마력 %.0f\n%s" % [character.display_name, style, character.base_max_hp, character.base_magic_power, character.description], func(): _select_character(character), 760)
		button.disabled = not unlocks.is_unlocked("characters", character.id)
		stack.add_child(button)
	stack.add_child(_button("뒤로", func(): _show_map_select(bool(get_meta(&"starting_endless", false)))))


func _select_character(character: CharacterDef) -> void:
	selected_character = character
	flow.transition(RunFlowController.State.STARTING_FAMILY_SELECT)
	_show_family_select()


func _show_family_select() -> void:
	var stack := _screen_stack("시작 카드군 선택", "초반 덱의 방향을 정합니다. 덱의 모든 카드는 자동 사이클에 배치됩니다")
	for family in selected_character.allowed_starting_families:
		if not unlocks.is_unlocked("families", family):
			continue
		var names: Array[String] = []
		for card in all_cards:
			if card.family_id == family:
				names.append(card.display_name)
		stack.add_child(_button("%s · %s" % [_family_name(family), ", ".join(names)], func(): _start_run(family), 760))
	stack.add_child(_button("뒤로", _show_character_select))


func _start_run(family: StringName) -> void:
	var survivor_ab := bool(get_meta(&"starting_survivor_ab", false))
	var mode := RunSession.Mode.SURVIVOR_AB if survivor_ab else RunSession.Mode.ENDLESS if bool(get_meta(&"starting_endless", false)) else RunSession.Mode.STANDARD
	session = RunSession.create(int(Time.get_ticks_msec()), selected_map.id, selected_character.id, family, mode)
	run_rng = RunRng.new(session.seed)
	deck = ContentFactory.starting_deck(family, all_cards)
	cycle = ContentFactory.default_cycle(deck)
	flow.attach_session(session)
	flow.transition(RunFlowController.State.RUN_MAP)
	if survivor_ab:
		_start_survivor_battle()
		return
	run_map = MapGenerator.generate(selected_map, run_rng)
	map_controller.initialize(run_map)
	_enter_first_combat_node()


func _enter_first_combat_node() -> void:
	var first_combat: MapNode
	for node in map_controller.available_nodes():
		if node.type == MapNode.Type.COMBAT:
			first_combat = node
			break
	if first_combat == null:
		_show_run_map()
		return
	if not map_controller.select(first_combat.id):
		_show_run_map()
		return
	session.visit_node(first_combat.id)
	_start_battle(MapNode.Type.COMBAT)


func _show_run_map() -> void:
	var stack := _screen_stack(selected_map.display_name, "노드를 고르면 진입 전 콤보 배치 화면이 열립니다 · 재화 %d · 덱 %d장" % [session.currency, deck.cards.size()])
	var route := Label.new()
	route.text = "진행: %s" % " → ".join(Array(session.visited_node_ids).map(func(id): return String(id)))
	route.add_theme_color_override("font_color", ArtDirection.PAPER_DIM)
	stack.add_child(route)
	var available := map_controller.available_nodes()
	for node in available:
		var button := _button("%s\n%s" % [_node_name(node.type), _node_description(node.type)], func(): _select_node(node), 760)
		stack.add_child(button)
	var deck_label := Label.new()
	deck_label.text = "사이클: %s" % _cycle_summary()
	deck_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	deck_label.add_theme_font_size_override("font_size", 16)
	stack.add_child(deck_label)
	stack.add_child(_button("콤보 배치 수정", func(): _show_combo_editor(null), 760))
	stack.add_child(_button("런 포기", func(): _show_result(false, {"reason": "포기"})))


func _select_node(node: MapNode) -> void:
	pending_node = node
	combo_editor_message = ""
	flow.transition(RunFlowController.State.DECK_EDIT)
	_show_combo_editor(node)


func _enter_pending_node() -> void:
	_normalize_cycle(false)
	var validation := ComboValidator.validate(deck, cycle)
	if not validation.valid:
		combo_editor_message = "모든 카드를 정확히 한 번씩 배치하고 빈 콤보가 없도록 해주세요."
		_show_combo_editor(pending_node)
		return
	if pending_node == null:
		flow.transition(RunFlowController.State.RUN_MAP)
		_show_run_map()
		return
	var node := pending_node
	pending_node = null
	if not map_controller.select(node.id):
		flow.state = RunFlowController.State.RUN_MAP
		_show_run_map()
		return
	session.visit_node(node.id)
	match node.type:
		MapNode.Type.COMBAT, MapNode.Type.ELITE, MapNode.Type.BOSS:
			_start_battle(node.type)
		MapNode.Type.SHOP:
			_show_shop()
		MapNode.Type.REST:
			_show_rest()
		MapNode.Type.EVENT:
			_show_event()


func _show_combo_editor(node: MapNode = null) -> void:
	if node != null:
		pending_node = node
	_normalize_cycle(false)
	if cycle.combos.is_empty():
		_ensure_combo(0)
	var destination := "편집 완료 후 맵으로 복귀" if pending_node == null else "%s 노드 진입 준비" % _node_name(pending_node.type)
	var stack := _screen_stack("콤보 슬롯 배치", "%s · 슬롯 수와 카드 발동 순서를 자유롭게 구성합니다" % destination)
	if combo_editor_message != "":
		var warning := Label.new()
		warning.text = combo_editor_message
		warning.add_theme_color_override("font_color", ArtDirection.DANGER)
		warning.add_theme_font_size_override("font_size", 18)
		stack.add_child(warning)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 12)
	toolbar.add_child(_button("＋ 콤보 슬롯 추가", _add_combo_slot, 230))
	var toolbar_hint := Label.new()
	toolbar_hint.text = "슬롯 삭제 시 카드는 남은 슬롯 중 회전 시간이 가장 짧은 곳으로 이동합니다"
	toolbar_hint.add_theme_color_override("font_color", ArtDirection.PAPER_DIM)
	toolbar_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toolbar.add_child(toolbar_hint)
	stack.add_child(toolbar)

	var scroll := ScrollContainer.new()
	scroll.name = "ComboEditorScroll"
	scroll.custom_minimum_size = Vector2(0, 260)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	stack.add_child(scroll)
	var board := HBoxContainer.new()
	board.name = "ComboEditorBoard"
	board.add_theme_constant_override("separation", 12)
	scroll.add_child(board)

	var assigned := {}
	for combo_index in range(cycle.combos.size()):
		var combo := cycle.combos[combo_index]
		var lane_index := combo_index
		var column := VBoxContainer.new()
		column.custom_minimum_size = Vector2(226, 0)
		var duration := _combo_duration(combo)
		var header := HBoxContainer.new()
		var heading := Label.new()
		heading.text = "COMBO %s\n%d장 · %.1f초/회전" % [_combo_label(combo_index), combo.card_instance_ids.size(), duration]
		heading.custom_minimum_size.x = 162
		heading.add_theme_font_size_override("font_size", 18)
		heading.add_theme_color_override("font_color", ArtDirection.CYAN)
		header.add_child(heading)
		var remove_lane := _button("슬롯\n삭제", func(): _remove_combo_slot(lane_index), 56)
		remove_lane.custom_minimum_size = Vector2(56, 48)
		remove_lane.disabled = cycle.combos.size() <= MIN_COMBO_SLOTS
		header.add_child(remove_lane)
		column.add_child(header)

		var drop_zone := ComboDropZone.new()
		drop_zone.configure(combo_index)
		drop_zone.add_theme_constant_override("separation", 4)
		drop_zone.card_dropped.connect(_drop_combo_card)
		column.add_child(drop_zone)
		for card_index in range(combo.card_instance_ids.size()):
			var card_id := combo.card_instance_ids[card_index]
			var card := deck.get_card(card_id)
			if card == null:
				continue
			assigned[card_id] = true
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 4)
			var card_button := ComboDragCard.new()
			card_button.configure(card_id, combo_index, card_index, _card_tile_text(card, card_index + 1))
			card_button.custom_minimum_size = Vector2(178, 78)
			card_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card_button.pressed.connect(func(): _move_card_to_next_slot(card_id))
			card_button.card_dropped.connect(_drop_combo_card)
			row.add_child(card_button)
			var order_controls := VBoxContainer.new()
			order_controls.add_theme_constant_override("separation", 3)
			var up := _button("↑", func(): _reorder_card(lane_index, card_id, -1), 38)
			up.custom_minimum_size = Vector2(38, 36)
			order_controls.add_child(up)
			var down := _button("↓", func(): _reorder_card(lane_index, card_id, 1), 38)
			down.custom_minimum_size = Vector2(38, 36)
			order_controls.add_child(down)
			row.add_child(order_controls)
			drop_zone.add_child(row)
		if combo.card_instance_ids.is_empty():
			var empty := Label.new()
			empty.text = "여기에 카드를 드롭"
			empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty.custom_minimum_size.y = 78
			empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
			empty.modulate = ArtDirection.MUTED
			drop_zone.add_child(empty)
		board.add_child(column)

	var unassigned_column := VBoxContainer.new()
	unassigned_column.custom_minimum_size = Vector2(226, 0)
	var unassigned_title := Label.new()
	unassigned_title.text = "미배치 카드"
	unassigned_title.add_theme_font_size_override("font_size", 18)
	unassigned_title.add_theme_color_override("font_color", ArtDirection.YELLOW)
	unassigned_column.add_child(unassigned_title)
	var unassigned_zone := ComboDropZone.new()
	unassigned_zone.configure(-1)
	unassigned_zone.add_theme_constant_override("separation", 4)
	unassigned_zone.card_dropped.connect(_drop_combo_card)
	unassigned_column.add_child(unassigned_zone)
	var unassigned_count := 0
	for card in deck.cards:
		if assigned.has(card.instance_id):
			continue
		var source_index := unassigned_count
		unassigned_count += 1
		var unassigned_card := ComboDragCard.new()
		unassigned_card.configure(card.instance_id, -1, source_index, "%s\n%s\n클릭: COMBO %s에 배치" % [card.display_name, _card_summary(card), _combo_label(0)])
		unassigned_card.custom_minimum_size = Vector2(218, 78)
		unassigned_card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		unassigned_card.pressed.connect(func(): _assign_card(card.instance_id, 0))
		unassigned_card.card_dropped.connect(_drop_combo_card)
		unassigned_zone.add_child(unassigned_card)
	if unassigned_count == 0:
		var all_set := Label.new()
		all_set.text = "모든 카드 배치 완료\n카드를 이곳에 드롭하면 미배치 상태로 이동"
		all_set.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		all_set.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		all_set.custom_minimum_size.y = 78
		all_set.mouse_filter = Control.MOUSE_FILTER_IGNORE
		all_set.modulate = ArtDirection.CYAN
		unassigned_zone.add_child(all_set)
	board.add_child(unassigned_column)

	var validation := ComboValidator.validate(deck, cycle)
	var status := Label.new()
	status.text = "✓ 배치 유효 — 각 콤보가 병렬로, 내부 카드는 위에서 아래 순서로 발동합니다" if validation.valid else "미완성 — 모든 카드를 정확히 한 번씩 배치하고 빈 콤보가 없도록 해주세요"
	status.add_theme_color_override("font_color", ArtDirection.CYAN if validation.valid else ArtDirection.YELLOW)
	stack.add_child(status)
	var confirm := _button("배치 확정%s" % (" 및 노드 진입" if pending_node != null else ""), _enter_pending_node, 760)
	confirm.disabled = not validation.valid
	stack.add_child(confirm)
	stack.add_child(_button("변경 취소 없이 맵으로 돌아가기", func(): pending_node = null; flow.state = RunFlowController.State.RUN_MAP; _show_run_map(), 760))


func _drop_combo_card(card_id: StringName, target_combo_index: int, target_card_index: int) -> void:
	if card_id == &"":
		return
	var source_combo_index := -1
	var source_card_index := -1
	for combo_index in range(cycle.combos.size()):
		var found := cycle.combos[combo_index].card_instance_ids.find(card_id)
		if found >= 0:
			source_combo_index = combo_index
			source_card_index = found
			break
	_remove_card_from_cycle(card_id)
	if target_combo_index >= 0:
		var target_combo := _ensure_combo(target_combo_index)
		var insertion_index := target_card_index
		if insertion_index < 0:
			insertion_index = target_combo.card_instance_ids.size()
		if source_combo_index == target_combo_index and source_card_index < insertion_index:
			insertion_index -= 1
		insertion_index = clampi(insertion_index, 0, target_combo.card_instance_ids.size())
		target_combo.card_instance_ids.insert(insertion_index, card_id)
	combo_editor_message = ""
	_show_combo_editor(pending_node)

func _ensure_combo(index: int) -> ComboState:
	while cycle.combos.size() <= index:
		cycle.combos.append(ComboState.create(_next_combo_id(), 0))
	return cycle.combos[index]


func _next_combo_id() -> StringName:
	var used := {}
	for combo in cycle.combos:
		used[combo.id] = true
	var suffix := 1
	while used.has(StringName("combo_%d" % suffix)):
		suffix += 1
	return StringName("combo_%d" % suffix)


func _combo_label(index: int) -> String:
	var number := index + 1
	var result := ""
	while number > 0:
		number -= 1
		result = String.chr(65 + (number % 26)) + result
		number = int(number / 26)
	return result


func _add_combo_slot() -> void:
	cycle.combos.append(ComboState.create(_next_combo_id(), 0))
	combo_editor_message = "새 콤보 슬롯을 추가했습니다. 카드를 배치하면 활성화됩니다."
	_show_combo_editor(pending_node)


func _remove_combo_slot(index: int) -> void:
	if not _remove_combo_slot_data(index):
		return
	combo_editor_message = "콤보 슬롯을 삭제하고 카드 순서를 가장 짧은 슬롯부터 재배치했습니다."
	_show_combo_editor(pending_node)


func _remove_combo_slot_data(index: int) -> bool:
	if cycle.combos.size() <= MIN_COMBO_SLOTS or index < 0 or index >= cycle.combos.size():
		return false
	var removed_cards: Array[StringName] = cycle.combos[index].card_instance_ids.duplicate()
	cycle.combos.remove_at(index)
	for card_id in removed_cards:
		var target_index := _shortest_combo_index()
		cycle.combos[target_index].card_instance_ids.append(card_id)
	return true


func _shortest_combo_index() -> int:
	if cycle.combos.is_empty():
		_ensure_combo(0)
	var best_index := 0
	var best_duration := INF
	for index in range(cycle.combos.size()):
		var duration := _combo_duration(cycle.combos[index])
		if duration < best_duration:
			best_duration = duration
			best_index = index
	return best_index


func _assign_card(card_id: StringName, combo_index: int) -> void:
	_remove_card_from_cycle(card_id)
	_ensure_combo(combo_index).card_instance_ids.append(card_id)
	combo_editor_message = ""
	_show_combo_editor(pending_node)


func _move_card_to_next_slot(card_id: StringName) -> void:
	if cycle.combos.is_empty():
		_ensure_combo(0)
	var current := -1
	for i in range(cycle.combos.size()):
		if card_id in cycle.combos[i].card_instance_ids:
			current = i
			break
	_remove_card_from_cycle(card_id)
	var target := 0 if current < 0 else (current + 1) % cycle.combos.size()
	cycle.combos[target].card_instance_ids.append(card_id)
	_show_combo_editor(pending_node)


func _reorder_card(combo_index: int, card_id: StringName, offset: int) -> void:
	var combo := _ensure_combo(combo_index)
	var from := combo.card_instance_ids.find(card_id)
	if from < 0:
		return
	var to := clampi(from + offset, 0, combo.card_instance_ids.size() - 1)
	if from != to:
		combo.card_instance_ids.remove_at(from)
		combo.card_instance_ids.insert(to, card_id)
	_show_combo_editor(pending_node)


func _remove_card_from_cycle(card_id: StringName) -> void:
	for combo in cycle.combos:
		combo.card_instance_ids.erase(card_id)


func _normalize_cycle(compact := false) -> void:
	var seen := {}
	for combo in cycle.combos:
		var clean: Array[StringName] = []
		for card_id in combo.card_instance_ids:
			if deck.get_card(card_id) != null and not seen.has(card_id):
				clean.append(card_id)
				seen[card_id] = true
		combo.card_instance_ids = clean
	if compact:
		cycle = _compacted_cycle_copy()


func _compacted_cycle_copy() -> CycleState:
	var compacted := CycleState.new()
	for combo in cycle.combos:
		if not combo.card_instance_ids.is_empty():
			compacted.combos.append(combo)
	return compacted


func _combo_duration(combo: ComboState) -> float:
	if combo == null:
		return 0.0
	var result := 0.0
	for card_id in combo.card_instance_ids:
		var card := deck.get_card(card_id)
		if card and card.card_def:
			result += card.card_def.execution_interval
	return result


func _card_summary(card: CardInstance) -> String:
	if card == null or card.card_def == null:
		return "-"
	var labels: Array[String] = card.card_def.targeting_labels()
	return "%s · %s · %.1fs · %s" % [_family_name(card.card_def.family_id), _rarity_name(card.card_def.rarity), card.card_def.execution_interval, " · ".join(labels)]


func _card_tile_text(card: CardInstance, sequence: int = -1) -> String:
	if card == null or card.card_def == null:
		return "-"
	var prefix := "%d. " % sequence if sequence > 0 else ""
	var labels: Array[String] = card.card_def.targeting_labels()
	return "%s%s\n%s · %s · %.1fs\n%s" % [prefix, card.display_name, _family_name(card.card_def.family_id), _rarity_name(card.card_def.rarity), card.card_def.execution_interval, " · ".join(labels)]


func _on_survivor_level_up(arena: BattleArena, level: int, xp: float, next_xp: float) -> void:
	if not is_instance_valid(arena) or arena.ended:
		return
	get_tree().paused = true
	survivor_reward_claimed = false
	_show_survivor_level_overlay(arena, level, xp, next_xp)


func _show_survivor_level_overlay(arena: BattleArena, level: int, xp: float, next_xp: float) -> void:
	if is_instance_valid(survivor_level_overlay):
		survivor_level_overlay.queue_free()
	survivor_level_overlay = CanvasLayer.new()
	survivor_level_overlay.name = "SurvivorLevelUpOverlay"
	survivor_level_overlay.layer = 100
	survivor_level_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(survivor_level_overlay)
	var overlay_root := Control.new()
	overlay_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_root.theme = ArtDirection.create_theme()
	survivor_level_overlay.add_child(overlay_root)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.025, 0.015, 0.035, 0.90)
	overlay_root.add_child(dim)
	var panel := PanelContainer.new()
	panel.position = Vector2(44, 24)
	panel.size = Vector2(1192, 672)
	panel.add_theme_stylebox_override("panel", ArtDirection.panel_style(ArtDirection.INK, ArtDirection.MAGENTA, 4, 1))
	overlay_root.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 7)
	margin.add_child(stack)
	var title := Label.new()
	title.text = "LEVEL %02d // BUILD BREAK" % level
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", ArtDirection.YELLOW)
	stack.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "전투 일시정지 · XP %.0f / %.0f · 보상 선택 후 콤보 슬롯과 카드 순서를 자유롭게 정비" % [xp, next_xp]
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", ArtDirection.CYAN)
	stack.add_child(subtitle)

	if cycle.combos.is_empty():
		_ensure_combo(0)
	if not survivor_reward_claimed:
		var offers := HBoxContainer.new()
		offers.add_theme_constant_override("separation", 10)
		var card_offers := RewardOfferService.create_offer(all_cards, deck, run_rng, 2)
		for card_def in card_offers:
			var card_button := _button("CARD\n%s · %s\n%.1fs · %s" % [card_def.display_name, _family_name(card_def.family_id), card_def.execution_interval, " · ".join(card_def.targeting_labels())], func(): _survivor_take_card(arena, card_def, level, xp, next_xp), 260)
			card_button.custom_minimum_size.y = 70
			card_button.tooltip_text = card_def.description
			offers.add_child(card_button)
		var relic := _survivor_next_relic(level)
		if relic.is_empty():
			var no_relic := _button("RELIC\n모든 유물 획득 완료", func(): pass, 260)
			no_relic.disabled = true
			offers.add_child(no_relic)
		else:
			var relic_button := _button("RELIC\n%s\n%s" % [relic["name"], relic["description"]], func(): _survivor_take_relic(arena, relic, level, xp, next_xp), 260)
			relic_button.custom_minimum_size.y = 70
			offers.add_child(relic_button)
		offers.add_child(_button("보상 건너뛰기\n덱 정비만", func(): survivor_reward_claimed = true; _show_survivor_level_overlay(arena, level, xp, next_xp), 200))
		stack.add_child(offers)
	else:
		var claimed := Label.new()
		claimed.text = "보상 선택 완료 · 아래에서 슬롯과 배치를 정비한 뒤 재개하세요"
		claimed.add_theme_color_override("font_color", ArtDirection.CYAN)
		claimed.add_theme_font_size_override("font_size", 16)
		stack.add_child(claimed)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 12)
	toolbar.add_child(_button("＋ COMBO SLOT", func(): _survivor_add_combo(arena, level, xp, next_xp), 220))
	var toolbar_hint := Label.new()
	toolbar_hint.text = "%d개 슬롯 · 가로/세로 스크롤 · 슬롯 삭제 시 카드는 자동 재배치" % cycle.combos.size()
	toolbar_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toolbar_hint.add_theme_color_override("font_color", ArtDirection.PAPER_DIM)
	toolbar.add_child(toolbar_hint)
	stack.add_child(toolbar)

	var scroll := ScrollContainer.new()
	scroll.name = "SurvivorComboScroll"
	scroll.custom_minimum_size.y = 330
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	stack.add_child(scroll)
	var board := HBoxContainer.new()
	board.name = "SurvivorComboBoard"
	board.add_theme_constant_override("separation", 10)
	scroll.add_child(board)

	for combo_index in range(cycle.combos.size()):
		var combo: ComboState = cycle.combos[combo_index]
		var lane_index := combo_index
		var column := VBoxContainer.new()
		column.custom_minimum_size.x = 226
		var header := HBoxContainer.new()
		var heading := Label.new()
		var duration := _combo_duration(combo)
		heading.text = "COMBO %s\n%d장 · %.1f초" % [_combo_label(combo_index), combo.card_instance_ids.size(), duration]
		heading.custom_minimum_size.x = 166
		heading.add_theme_font_size_override("font_size", 16)
		heading.add_theme_color_override("font_color", ArtDirection.CYAN)
		header.add_child(heading)
		var remove_lane := _button("−\nSLOT", func(): _survivor_remove_combo(arena, lane_index, level, xp, next_xp), 52)
		remove_lane.custom_minimum_size = Vector2(52, 46)
		remove_lane.disabled = cycle.combos.size() <= MIN_COMBO_SLOTS
		header.add_child(remove_lane)
		column.add_child(header)

		var zone := ComboDropZone.new()
		zone.configure(combo_index)
		zone.add_theme_constant_override("separation", 4)
		zone.card_dropped.connect(func(card_id, target_combo, target_index): _survivor_drop_card(arena, card_id, target_combo, target_index, level, xp, next_xp))
		column.add_child(zone)
		for card_index in range(combo.card_instance_ids.size()):
			var card_id := combo.card_instance_ids[card_index]
			var card := deck.get_card(card_id)
			if card == null:
				continue
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 4)
			var drag_card := ComboDragCard.new()
			drag_card.configure(card_id, combo_index, card_index, _card_tile_text(card, card_index + 1))
			drag_card.custom_minimum_size = Vector2(176, 76)
			drag_card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			drag_card.card_dropped.connect(func(dropped_id, target_combo, target_index): _survivor_drop_card(arena, dropped_id, target_combo, target_index, level, xp, next_xp))
			row.add_child(drag_card)
			var remove := _button("×", func(): _survivor_delete_card(arena, card_id, level, xp, next_xp), 38)
			remove.custom_minimum_size = Vector2(38, 76)
			remove.disabled = deck.cards.size() <= 1 or card.undeletable or card.locked
			row.add_child(remove)
			zone.add_child(row)
		if combo.card_instance_ids.is_empty():
			var empty := Label.new()
			empty.text = "DROP CARD\n빈 슬롯은 전투 재개 전 채워주세요"
			empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty.custom_minimum_size.y = 76
			empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
			empty.add_theme_color_override("font_color", ArtDirection.YELLOW)
			zone.add_child(empty)
		board.add_child(column)

	var delete_column := VBoxContainer.new()
	delete_column.custom_minimum_size.x = 210
	var delete_title := Label.new()
	delete_title.text = "DELETE ZONE"
	delete_title.add_theme_font_size_override("font_size", 16)
	delete_title.add_theme_color_override("font_color", ArtDirection.DANGER)
	delete_column.add_child(delete_title)
	var delete_zone := ComboDropZone.new()
	delete_zone.configure(-2)
	delete_zone.custom_minimum_size.y = 132
	delete_zone.card_dropped.connect(func(card_id, _target_combo, _target_index): _survivor_delete_card(arena, card_id, level, xp, next_xp))
	delete_column.add_child(delete_zone)
	var delete_hint := Label.new()
	delete_hint.text = "카드를 여기로 드래그\n최소 1장은 유지"
	delete_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	delete_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	delete_hint.custom_minimum_size.y = 112
	delete_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	delete_hint.add_theme_color_override("font_color", ArtDirection.DANGER)
	delete_zone.add_child(delete_hint)
	board.add_child(delete_column)

	var validation := ComboValidator.validate(deck, cycle)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 14)
	var state_label := Label.new()
	state_label.text = "VALID // %d개 콤보로 전투 재개 가능" % cycle.combos.size() if validation.valid else "INVALID // 모든 카드를 배치하고 빈 콤보를 채우거나 삭제하세요"
	state_label.custom_minimum_size.x = 790
	state_label.add_theme_font_size_override("font_size", 15)
	state_label.add_theme_color_override("font_color", ArtDirection.CYAN if validation.valid else ArtDirection.DANGER)
	footer.add_child(state_label)
	var resume := _button("전투 재개", func(): _resume_survivor(arena), 300)
	resume.disabled = not survivor_reward_claimed or not validation.valid
	footer.add_child(resume)
	stack.add_child(footer)


func _survivor_add_combo(arena: BattleArena, level: int, xp: float, next_xp: float) -> void:
	cycle.combos.append(ComboState.create(_next_combo_id(), 0))
	_show_survivor_level_overlay(arena, level, xp, next_xp)


func _survivor_remove_combo(arena: BattleArena, combo_index: int, level: int, xp: float, next_xp: float) -> void:
	if not _remove_combo_slot_data(combo_index):
		return
	if ComboValidator.validate(deck, cycle)["valid"]:
		arena.refresh_survivor_cycle()
	_show_survivor_level_overlay(arena, level, xp, next_xp)


func _survivor_best_lane(_card_def: CardDef) -> int:
	return _shortest_combo_index()


func _survivor_take_card(arena: BattleArena, card_def: CardDef, level: int, xp: float, next_xp: float) -> void:
	var lane := _survivor_best_lane(card_def)
	if lane < 0:
		return
	var instance := CardInstance.create(card_def, &"survivor_level")
	if not deck.add_card(instance):
		return
	_ensure_combo(lane).card_instance_ids.append(instance.instance_id)
	_normalize_cycle(false)
	survivor_reward_claimed = true
	arena.refresh_survivor_cycle()
	_show_survivor_level_overlay(arena, level, xp, next_xp)


func _survivor_next_relic(level: int) -> Dictionary:
	var available: Array[Dictionary] = []
	for relic in ContentFactory.survivor_relics():
		if not session.relic_ids.has(StringName(relic.get("id", ""))):
			available.append(relic)
	if available.is_empty():
		return {}
	return available[level % available.size()]


func _survivor_take_relic(arena: BattleArena, relic: Dictionary, level: int, xp: float, next_xp: float) -> void:
	var relic_id := StringName(relic.get("id", ""))
	if relic_id == &"" or session.relic_ids.has(relic_id):
		return
	session.relic_ids.append(relic_id)
	arena.apply_survivor_relic(relic)
	survivor_reward_claimed = true
	_show_survivor_level_overlay(arena, level, xp, next_xp)


func _survivor_drop_card(arena: BattleArena, card_id: StringName, target_combo_index: int, target_card_index: int, level: int, xp: float, next_xp: float) -> void:
	if target_combo_index == -2:
		_survivor_delete_card(arena, card_id, level, xp, next_xp)
		return
	var source_combo_index := -1
	var source_card_index := -1
	for combo_index in range(cycle.combos.size()):
		var found := cycle.combos[combo_index].card_instance_ids.find(card_id)
		if found >= 0:
			source_combo_index = combo_index
			source_card_index = found
			break
	_remove_card_from_cycle(card_id)
	var target_combo := _ensure_combo(target_combo_index)
	var insertion_index := target_card_index
	if insertion_index < 0:
		insertion_index = target_combo.card_instance_ids.size()
	if source_combo_index == target_combo_index and source_card_index < insertion_index:
		insertion_index -= 1
	insertion_index = clampi(insertion_index, 0, target_combo.card_instance_ids.size())
	target_combo.card_instance_ids.insert(insertion_index, card_id)
	_normalize_cycle(false)
	if ComboValidator.validate(deck, cycle)["valid"]:
		arena.refresh_survivor_cycle()
	_show_survivor_level_overlay(arena, level, xp, next_xp)


func _survivor_delete_card(arena: BattleArena, card_id: StringName, level: int, xp: float, next_xp: float) -> void:
	if deck.cards.size() <= 1:
		return
	var card := deck.get_card(card_id)
	if card == null or card.locked or card.undeletable:
		return
	_remove_card_from_cycle(card_id)
	deck.remove_card(card_id)
	_normalize_cycle(false)
	if ComboValidator.validate(deck, cycle)["valid"]:
		arena.refresh_survivor_cycle()
	_show_survivor_level_overlay(arena, level, xp, next_xp)


func _resume_survivor(arena: BattleArena) -> void:
	if not survivor_reward_claimed or not ComboValidator.validate(deck, cycle)["valid"]:
		return
	if is_instance_valid(survivor_level_overlay):
		survivor_level_overlay.queue_free()
	survivor_level_overlay = null
	arena.resume_survivor_after_levelup()
	get_tree().paused = false

func _start_survivor_battle() -> void:
	flow.transition(RunFlowController.State.ENCOUNTER)
	_clear_screen()
	survivor_arena = BattleArena.new()
	survivor_arena.name = "SurvivorArena_B"
	root_control.add_child(survivor_arena)
	survivor_arena.completed.connect(func(success, summary): call_deferred(&"_on_survivor_completed", success, summary))
	survivor_arena.survivor_level_up_requested.connect(func(level, xp, next_xp): _on_survivor_level_up(survivor_arena, level, xp, next_xp))
	survivor_arena.initialize_survivor(selected_character, deck, cycle, run_rng)


func _on_survivor_completed(_success: bool, summary: Dictionary) -> void:
	get_tree().paused = false
	if is_instance_valid(survivor_level_overlay):
		survivor_level_overlay.queue_free()
	_show_result(false, summary)


func _start_battle(type: MapNode.Type) -> void:
	flow.transition(RunFlowController.State.ENCOUNTER)
	_clear_screen()
	var arena := BattleArena.new()
	root_control.add_child(arena)
	arena.completed.connect(func(success, summary): call_deferred(&"_on_battle_completed", success, summary))
	var scale := EndlessService.difficulty_multiplier(session.endless_loop) if session.mode == RunSession.Mode.ENDLESS else 1.0
	arena.initialize(type, selected_character, deck, cycle, scale, run_rng)


func _on_battle_completed(success: bool, summary: Dictionary) -> void:
	if not success:
		_show_result(false, summary)
		return
	map_controller.complete_current()
	var type: int = summary.get("node_type", MapNode.Type.COMBAT)
	session.add_currency(45 if type == MapNode.Type.ELITE else 100 if type == MapNode.Type.BOSS else 25)
	if type == MapNode.Type.BOSS:
		unlocks.record_clear(selected_map.id, session.starting_family_id, session.endless_loop)
		if session.mode == RunSession.Mode.ENDLESS:
			EndlessService.advance(session)
			run_map = MapGenerator.generate(selected_map, run_rng)
			map_controller.initialize(run_map)
			_show_run_map()
		else:
			_show_result(true, summary)
		return
	flow.transition(RunFlowController.State.REWARD)
	_show_reward()


func _show_reward() -> void:
	var stack := _screen_stack("카드 보상", "3장 중 1장을 선택하거나 건너뜁니다. 현재 덱 카드군에 가중치가 적용됩니다")
	var offers := RewardOfferService.create_offer(all_cards, deck, run_rng, 3)
	for card in offers:
		stack.add_child(_button("%s · %s · %s · %.1fs · %s" % [card.display_name, _family_name(card.family_id), _rarity_name(card.rarity), card.execution_interval, " · ".join(card.targeting_labels())], func(): _take_reward(card), 700))
	stack.add_child(_button("건너뛰기", _finish_node))


func _take_reward(card: CardDef) -> void:
	deck.add_card(CardInstance.create(card, &"reward"))
	_finish_node()


func _show_shop() -> void:
	flow.transition(RunFlowController.State.SHOP)
	var stack := _screen_stack("상점", "카드 구매와 제거 · 현재 재화 %d" % session.currency)
	var offers := RewardOfferService.create_offer(all_cards, deck, run_rng, 3)
	for card in offers:
		var button := _button("구매 40 · %s" % card.display_name, func(): _buy_card(card))
		button.disabled = session.currency < 40
		stack.add_child(button)
	if not deck.cards.is_empty():
		var remove := _button("제거 30 · %s" % deck.cards[0].display_name, func(): _remove_first_card(30))
		remove.disabled = session.currency < 30 or deck.cards.size() <= 1
		stack.add_child(remove)
	stack.add_child(_button("상점 나가기", _finish_node))


func _buy_card(card: CardDef) -> void:
	if session.spend_currency(40):
		deck.add_card(CardInstance.create(card, &"shop"))
	_show_shop()


func _remove_first_card(price: int) -> void:
	if deck.cards.size() <= 1 or not session.spend_currency(price):
		return
	var removed_id := deck.cards[0].instance_id
	deck.remove_card(removed_id)
	_remove_card_from_cycle(removed_id)
	_show_shop()


func _show_rest() -> void:
	flow.transition(RunFlowController.State.REST)
	var stack := _screen_stack("휴식", "행동 후 다음 노드 전투에서 완전히 회복합니다")
	for card in deck.cards:
		stack.add_child(_button("강화 · %s +%d" % [card.display_name, card.upgrade_level], func(): _upgrade_card(card)))
		if stack.get_child_count() > 7:
			break
	stack.add_child(_button("정비만 하고 이동", _finish_node))


func _upgrade_card(card: CardInstance) -> void:
	CardUpgradeService.upgrade(card)
	_finish_node()


func _show_event() -> void:
	flow.transition(RunFlowController.State.EVENT)
	var stack := _screen_stack("불안정한 마력 장치", "장치 안쪽에서 카드의 잔상이 반복해서 회전하고 있다")
	stack.add_child(_button("재화 20을 투입해 첫 카드를 강화", _event_upgrade))
	stack.add_child(_button("장치를 분해해 재화 15 획득", func(): session.add_currency(15); _finish_node()))
	stack.add_child(_button("지나간다", _finish_node))


func _event_upgrade() -> void:
	if session.spend_currency(20) and not deck.cards.is_empty():
		CardUpgradeService.upgrade(deck.cards[0])
	_finish_node()


func _finish_node() -> void:
	map_controller.complete_current()
	flow.state = RunFlowController.State.RUN_MAP
	_show_run_map()


func _show_result(success: bool, summary: Dictionary) -> void:
	if session:
		session.success = success
		session.ended = true
	flow.state = RunFlowController.State.RESULT
	var survivor_result := session != null and session.mode == RunSession.Mode.SURVIVOR_AB
	var title := "B · 생존 기록" if survivor_result else "런 클리어" if success else "런 종료"
	var subtitle := "무한 생존 실험 결과 · 같은 시작 빌드로 A안과 비교할 수 있습니다" if survivor_result else "보스 검증을 통과했습니다" if success else "빌드를 정비하고 다시 도전하세요"
	var stack := _screen_stack(title, subtitle)
	var report := Label.new()
	if survivor_result:
		var survived := int(summary.get("elapsed", 0.0))
		report.text = "실험안: B · 무한 생존\n맵: %s\n캐릭터: %s\n카드군: %s\n생존 시간: %02d:%02d\n도달 레벨: %d\n덱: %d장\n유물: %d개\n처치: %d\n종료 사유: %s" % [selected_map.display_name, selected_character.display_name, _family_name(session.starting_family_id), survived / 60, survived % 60, int(summary.get("level", 1)), deck.cards.size(), int(summary.get("relics", 0)), int(summary.get("kills", 0)), summary.get("reason", "체력 0")]
	else:
		report.text = "실험안: A · 노드 런\n맵: %s\n캐릭터: %s\n카드군: %s\n덱: %d장\n재화: %d\n처치: %d\n종료 사유: %s" % [selected_map.display_name, selected_character.display_name, _family_name(session.starting_family_id), deck.cards.size(), session.currency, int(summary.get("kills", 0)), summary.get("reason", "보스 처치" if success else "체력 0")]
	report.add_theme_font_size_override("font_size", 20)
	stack.add_child(report)
	stack.add_child(_button("메인 메뉴", func(): flow.state = RunFlowController.State.MAIN_MENU; _show_main_menu()))


func _family_name(id: StringName) -> String:
	return {&"sword": "검술", &"spear": "창술", &"blunt": "둔기", &"fire": "불", &"water": "물", &"poison": "독", &"neutral": "중립"}.get(id, String(id))



func _rarity_name(rarity: CardDef.Rarity) -> String:
	return ["일반", "희귀", "특급", "영웅", "전설"][rarity]

func _node_name(type: MapNode.Type) -> String:
	return ["시작", "전투", "엘리트", "상점", "휴식", "이벤트", "보스"][type]


func _node_description(type: MapNode.Type) -> String:
	return {
		MapNode.Type.COMBAT: "제한 시간 동안 생존 · 카드 보상",
		MapNode.Type.ELITE: "네임드 압박 · 많은 재화와 카드 보상",
		MapNode.Type.SHOP: "카드 구매 및 제거",
		MapNode.Type.REST: "완전 회복 및 카드 강화",
		MapNode.Type.EVENT: "선택에 따라 덱과 재화 변화",
		MapNode.Type.BOSS: "완성된 빌드 검증",
	}.get(type, "")


func _cycle_summary() -> String:
	var groups: Array[String] = []
	for combo in cycle.combos:
		var names: Array[String] = []
		for card_id in combo.card_instance_ids:
			var card := deck.get_card(card_id)
			if card:
				names.append(card.display_name)
		groups.append("[%s]" % " → ".join(names))
	return " → ".join(groups)
