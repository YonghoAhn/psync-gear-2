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
var selected_family: StringName = &""
var root_control: Control
var pending_node: MapNode
var combo_editor_message := ""
var survivor_arena: BattleArena
var survivor_level_overlay: CanvasLayer
var survivor_reward_claimed := false
enum SurvivorLevelStage { REWARD, REFINE }
var survivor_level_stage := SurvivorLevelStage.REWARD
var survivor_reward_view := "acquire"
var survivor_level_action := ""
var survivor_card_rerolls_left := 1
var survivor_card_offers: Array[CardDef] = []
const MIN_COMBO_SLOTS := 1
var card_codex_family_filter: StringName = &"all"
var card_codex_rarity_filter := -1
var card_codex_selected_id: StringName = &""
var enemy_codex_rank_filter := -1
var enemy_codex_selected_id: StringName = &""
var map_codex_selected_id: StringName = &""


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
	for family in [&"sword", &"spear", &"blunt", &"fire", &"water", &"poison"]:
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
	var stack := _screen_stack("CARBO", "무한 생존 · 경험치 레벨업과 덱 정제로 한계를 돌파하세요")
	_add_menu_key_art()
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 34
	stack.add_child(spacer)
	stack.add_child(_button("게임 시작 · 무한 생존", _begin_survivor))
	stack.add_child(_button("카드 도감 · CARD ARCHIVE", _open_card_codex))
	stack.add_child(_button("적 도감 · ENEMY ARCHIVE", _open_enemy_codex))
	stack.add_child(_button("맵 도감 · MAP ARCHIVE", _open_map_codex))
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


func _open_enemy_codex() -> void:
	enemy_codex_rank_filter = -1
	var enemies := ContentFactory.all_enemies()
	enemy_codex_selected_id = enemies[0].id if not enemies.is_empty() else &""
	_show_enemy_codex()


func _show_enemy_codex() -> void:
	_clear_screen()
	var all_enemies := ContentFactory.all_enemies()
	var filtered: Array[EnemyDef] = []
	for enemy in all_enemies:
		if enemy_codex_rank_filter >= 0 and enemy.rank != enemy_codex_rank_filter:
			continue
		filtered.append(enemy)
	var selected: EnemyDef = null
	for enemy in filtered:
		if enemy.id == enemy_codex_selected_id:
			selected = enemy
			break
	if selected == null and not filtered.is_empty():
		selected = filtered[0]
		enemy_codex_selected_id = selected.id

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
	title.text = "ENEMY ARCHIVE // 적 도감"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", ArtDirection.PAPER)
	title.add_theme_color_override("font_shadow_color", ArtDirection.MAGENTA)
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 2)
	header.add_child(title)
	var count_label := Label.new()
	count_label.name = "EnemyCodexCount"
	count_label.text = "%d / %d ENEMIES" % [filtered.size(), all_enemies.size()]
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 18)
	count_label.add_theme_color_override("font_color", ArtDirection.YELLOW)
	header.add_child(count_label)
	header.add_child(_button("메인 메뉴", _show_main_menu, 150))
	stack.add_child(header)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 10)
	var rank_label := Label.new()
	rank_label.text = "위험 등급"
	rank_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rank_label.add_theme_color_override("font_color", ArtDirection.CYAN)
	toolbar.add_child(rank_label)
	var rank_select := OptionButton.new()
	rank_select.name = "EnemyCodexRankFilter"
	rank_select.custom_minimum_size = Vector2(210, 42)
	rank_select.add_item("전체 적")
	for rank in range(EnemyDef.Rank.size()):
		rank_select.add_item(_enemy_rank_name(rank as EnemyDef.Rank))
	rank_select.select(enemy_codex_rank_filter + 1)
	rank_select.item_selected.connect(_set_enemy_codex_rank_filter)
	toolbar.add_child(rank_select)
	var hint := Label.new()
	hint.text = "등장 단계와 예고 패턴, 우선 처리 대상을 확인할 수 있습니다"
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", ArtDirection.PAPER_DIM)
	toolbar.add_child(hint)
	stack.add_child(toolbar)
	stack.add_child(HSeparator.new())

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	stack.add_child(body)
	var enemy_scroll := ScrollContainer.new()
	enemy_scroll.name = "EnemyCodexScroll"
	enemy_scroll.custom_minimum_size.x = 790
	enemy_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	enemy_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	enemy_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	body.add_child(enemy_scroll)
	var grid := GridContainer.new()
	grid.name = "EnemyCodexGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	enemy_scroll.add_child(grid)

	for enemy in filtered:
		var entry_id := enemy.id
		var tile := Button.new()
		tile.name = "EnemyCodexEntry_%s" % enemy.id
		tile.set_meta(&"enemy_id", enemy.id)
		tile.text = "%s
%s · %s · %s
HP %.0f · 공격 %.1f · 속도 %.0f
%s" % [enemy.display_name, _enemy_rank_name(enemy.rank), _enemy_role_name(enemy.role), _enemy_spawn_text(enemy), enemy.base_max_hp, enemy.base_attack_power, enemy.base_move_speed, " / ".join(enemy.pattern_names)]
		tile.tooltip_text = enemy.description
		tile.custom_minimum_size = Vector2(375, 142)
		tile.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tile.add_theme_font_size_override("font_size", 15)
		tile.add_theme_color_override("font_color", ArtDirection.PAPER)
		tile.add_theme_color_override("font_hover_color", ArtDirection.YELLOW)
		var border_color := ArtDirection.YELLOW if enemy.id == enemy_codex_selected_id else _enemy_rank_color(enemy.rank)
		tile.add_theme_stylebox_override("normal", ArtDirection.panel_style(Color(0.075, 0.055, 0.095, 0.97), border_color, 2 if enemy.id == enemy_codex_selected_id else 1, 1))
		tile.add_theme_stylebox_override("hover", ArtDirection.panel_style(Color(0.12, 0.07, 0.14, 0.99), ArtDirection.YELLOW, 3, 1))
		tile.pressed.connect(func(): _select_enemy_codex_entry(entry_id))
		grid.add_child(tile)

	var detail_panel := PanelContainer.new()
	detail_panel.name = "EnemyCodexDetail"
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
	detail_scroll.add_child(_build_enemy_codex_detail(selected))


func _set_enemy_codex_rank_filter(index: int) -> void:
	enemy_codex_rank_filter = clampi(index - 1, -1, EnemyDef.Rank.size() - 1)
	_show_enemy_codex()


func _select_enemy_codex_entry(enemy_id: StringName) -> void:
	enemy_codex_selected_id = enemy_id
	_show_enemy_codex()


func _build_enemy_codex_detail(enemy: EnemyDef) -> Control:
	var detail := VBoxContainer.new()
	detail.custom_minimum_size.x = 332
	detail.add_theme_constant_override("separation", 9)
	if enemy == null:
		var empty := Label.new()
		empty.text = "표시할 적이 없습니다."
		detail.add_child(empty)
		return detail
	var title := Label.new()
	title.text = enemy.display_name
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", _enemy_rank_color(enemy.rank))
	detail.add_child(title)
	var identity := Label.new()
	identity.text = "%s · %s · %s" % [_enemy_rank_name(enemy.rank), _enemy_role_name(enemy.role), _enemy_spawn_text(enemy)]
	identity.add_theme_font_size_override("font_size", 16)
	identity.add_theme_color_override("font_color", ArtDirection.YELLOW)
	detail.add_child(identity)
	detail.add_child(HSeparator.new())
	var description := Label.new()
	description.text = enemy.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 17)
	description.add_theme_color_override("font_color", ArtDirection.PAPER)
	detail.add_child(description)
	detail.add_child(HSeparator.new())
	var stats_title := Label.new()
	stats_title.text = "기본 전투 프로필"
	stats_title.add_theme_font_size_override("font_size", 18)
	stats_title.add_theme_color_override("font_color", ArtDirection.MAGENTA)
	detail.add_child(stats_title)
	var stats := Label.new()
	stats.text = "체력  %.0f
공격력  %.1f
이동 속도  %.0f
방어력  %.0f
접촉 피해  %.1f" % [enemy.base_max_hp, enemy.base_attack_power, enemy.base_move_speed, enemy.base_defense, enemy.contact_damage]
	stats.add_theme_font_size_override("font_size", 15)
	stats.add_theme_color_override("font_color", ArtDirection.PAPER_DIM)
	detail.add_child(stats)
	detail.add_child(HSeparator.new())
	var pattern_title := Label.new()
	pattern_title.text = "공격 패턴"
	pattern_title.add_theme_font_size_override("font_size", 18)
	pattern_title.add_theme_color_override("font_color", ArtDirection.CYAN)
	detail.add_child(pattern_title)
	for pattern in enemy.pattern_names:
		var row := Label.new()
		row.text = "◆ %s" % pattern
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_theme_color_override("font_color", ArtDirection.PAPER)
		detail.add_child(row)
	detail.add_child(HSeparator.new())
	var counter_title := Label.new()
	counter_title.text = "대응법"
	counter_title.add_theme_font_size_override("font_size", 18)
	counter_title.add_theme_color_override("font_color", ArtDirection.YELLOW)
	detail.add_child(counter_title)
	var counter := Label.new()
	counter.text = enemy.counterplay
	counter.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	counter.add_theme_font_size_override("font_size", 15)
	counter.add_theme_color_override("font_color", ArtDirection.PAPER)
	detail.add_child(counter)
	return detail


func _enemy_rank_name(rank: EnemyDef.Rank) -> String:
	return ["일반", "네임드", "보스"][rank]


func _enemy_role_name(role: EnemyDef.Role) -> String:
	return ["근접 추적", "원거리 사격", "지원", "소환", "방해", "돌격", "자폭", "방패"][role]


func _enemy_rank_color(rank: EnemyDef.Rank) -> Color:
	return [ArtDirection.CYAN, ArtDirection.MAGENTA, ArtDirection.YELLOW][rank]


func _enemy_spawn_text(enemy: EnemyDef) -> String:
	if enemy.rank == EnemyDef.Rank.BOSS:
		return "%d레벨 주기" % enemy.spawn_tier
	if enemy.rank == EnemyDef.Rank.NAMED:
		return "%d레벨 주기" % enemy.spawn_tier
	return ["초반 출현", "중반 해금", "후반 해금"][clampi(enemy.spawn_tier - 1, 0, 2)]


func _open_map_codex() -> void:
	map_codex_selected_id = all_maps[0].id if not all_maps.is_empty() else &""
	_show_map_codex()


func _show_map_codex() -> void:
	_clear_screen()
	var selected: MapDef = null
	for map in all_maps:
		if map.id == map_codex_selected_id:
			selected = map
			break
	if selected == null and not all_maps.is_empty():
		selected = all_maps[0]
		map_codex_selected_id = selected.id
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	root_control.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	margin.add_child(stack)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	var title := Label.new()
	title.text = "MAP ARCHIVE // 맵 도감"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", ArtDirection.PAPER)
	title.add_theme_color_override("font_shadow_color", ArtDirection.CYAN)
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 2)
	header.add_child(title)
	var count_label := Label.new()
	count_label.name = "MapCodexCount"
	count_label.text = "%d MAPS" % all_maps.size()
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 18)
	count_label.add_theme_color_override("font_color", ArtDirection.YELLOW)
	header.add_child(count_label)
	header.add_child(_button("메인 메뉴", _show_main_menu, 150))
	stack.add_child(header)
	var hint := Label.new()
	hint.text = "전장의 생존 규칙과 출현 로스터를 미리 확인할 수 있습니다"
	hint.add_theme_color_override("font_color", ArtDirection.CYAN)
	stack.add_child(hint)
	stack.add_child(HSeparator.new())
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	stack.add_child(body)
	var map_scroll := ScrollContainer.new()
	map_scroll.name = "MapCodexScroll"
	map_scroll.custom_minimum_size.x = 410
	map_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	map_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	body.add_child(map_scroll)
	var list := VBoxContainer.new()
	list.name = "MapCodexList"
	list.custom_minimum_size.x = 390
	list.add_theme_constant_override("separation", 10)
	map_scroll.add_child(list)
	for map in all_maps:
		var entry_id := map.id
		var tile := Button.new()
		tile.name = "MapCodexEntry_%s" % map.id
		tile.text = "%s
%s
%s" % [map.display_name, "다각형 생존 전장" if map.arena_shape == MapDef.ArenaShape.POLYGON else "원형 생존 전장", map.description.left(62)]
		tile.tooltip_text = map.description
		tile.custom_minimum_size = Vector2(390, 150)
		tile.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tile.add_theme_font_size_override("font_size", 16)
		tile.add_theme_color_override("font_color", ArtDirection.PAPER)
		var border_color := ArtDirection.YELLOW if map.id == map_codex_selected_id else ArtDirection.CYAN
		tile.add_theme_stylebox_override("normal", ArtDirection.panel_style(Color(0.075, 0.055, 0.095, 0.97), border_color, 2 if map.id == map_codex_selected_id else 1, 1))
		tile.add_theme_stylebox_override("hover", ArtDirection.panel_style(Color(0.12, 0.07, 0.14, 0.99), ArtDirection.YELLOW, 3, 1))
		tile.pressed.connect(func(): _select_map_codex_entry(entry_id))
		list.add_child(tile)
	var detail_panel := PanelContainer.new()
	detail_panel.name = "MapCodexDetail"
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_stylebox_override("panel", ArtDirection.panel_style(ArtDirection.INK, ArtDirection.CYAN, 3, 1))
	body.add_child(detail_panel)
	var detail_margin := MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", 22)
	detail_margin.add_theme_constant_override("margin_right", 22)
	detail_margin.add_theme_constant_override("margin_top", 18)
	detail_margin.add_theme_constant_override("margin_bottom", 18)
	detail_panel.add_child(detail_margin)
	var detail_scroll := ScrollContainer.new()
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	detail_margin.add_child(detail_scroll)
	detail_scroll.add_child(_build_map_codex_detail(selected))


func _select_map_codex_entry(map_id: StringName) -> void:
	map_codex_selected_id = map_id
	_show_map_codex()


func _build_map_codex_detail(map: MapDef) -> Control:
	var detail := VBoxContainer.new()
	detail.custom_minimum_size.x = 690
	detail.add_theme_constant_override("separation", 10)
	if map == null:
		var empty := Label.new()
		empty.text = "표시할 맵이 없습니다."
		detail.add_child(empty)
		return detail
	var title := Label.new()
	title.text = map.display_name
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", ArtDirection.CYAN)
	detail.add_child(title)
	var identity := Label.new()
	identity.text = "%s · 무한 생존 전용" % ("다각형 전장" if map.arena_shape == MapDef.ArenaShape.POLYGON else "원형 전장")
	identity.add_theme_font_size_override("font_size", 16)
	identity.add_theme_color_override("font_color", ArtDirection.YELLOW)
	detail.add_child(identity)
	detail.add_child(HSeparator.new())
	var description := Label.new()
	description.text = map.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 18)
	description.add_theme_color_override("font_color", ArtDirection.PAPER)
	detail.add_child(description)
	var rules_title := Label.new()
	rules_title.text = "생존 규칙"
	rules_title.add_theme_font_size_override("font_size", 19)
	rules_title.add_theme_color_override("font_color", ArtDirection.MAGENTA)
	detail.add_child(rules_title)
	var rules := Label.new()
	rules.text = map.survival_rules
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.add_theme_font_size_override("font_size", 16)
	rules.add_theme_color_override("font_color", ArtDirection.PAPER)
	detail.add_child(rules)
	detail.add_child(HSeparator.new())
	var feature_title := Label.new()
	feature_title.text = "전장 특성"
	feature_title.add_theme_font_size_override("font_size", 19)
	feature_title.add_theme_color_override("font_color", ArtDirection.CYAN)
	detail.add_child(feature_title)
	for feature in map.environment_features:
		var row := Label.new()
		row.text = "◆ %s" % feature
		row.add_theme_color_override("font_color", ArtDirection.PAPER)
		detail.add_child(row)
	var roster_title := Label.new()
	roster_title.text = "출현 로스터"
	roster_title.add_theme_font_size_override("font_size", 19)
	roster_title.add_theme_color_override("font_color", ArtDirection.YELLOW)
	detail.add_child(roster_title)
	for item in map.enemy_roster_summary:
		var row := Label.new()
		row.text = "◆ %s" % item
		row.add_theme_color_override("font_color", ArtDirection.PAPER)
		detail.add_child(row)
	var roster_names: Array[String] = []
	for enemy in ContentFactory.all_enemies():
		roster_names.append("%s [%s]" % [enemy.display_name, _enemy_rank_name(enemy.rank)])
	var names := Label.new()
	names.text = "
".join(roster_names)
	names.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	names.add_theme_font_size_override("font_size", 14)
	names.add_theme_color_override("font_color", ArtDirection.PAPER_DIM)
	detail.add_child(names)
	return detail

func _begin_survivor() -> void:
	selected_character = null
	selected_family = &""
	selected_map = null
	for character in all_characters:
		if unlocks.is_unlocked("characters", character.id):
			selected_character = character
			break
	flow.transition(RunFlowController.State.CHARACTER_SELECT)
	_show_character_select()


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


func _selection_stack(title_text: String, subtitle_text: String, step_text: String) -> VBoxContainer:
	_clear_screen()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	root_control.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	margin.add_child(stack)
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 72
	header.add_theme_constant_override("separation", 14)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", ArtDirection.PAPER)
	title.add_theme_color_override("font_shadow_color", ArtDirection.MAGENTA)
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title_box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = subtitle_text
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", ArtDirection.CYAN)
	title_box.add_child(subtitle)
	header.add_child(title_box)
	var step := Label.new()
	step.text = step_text
	step.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	step.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	step.custom_minimum_size = Vector2(150, 48)
	step.add_theme_font_size_override("font_size", 17)
	step.add_theme_color_override("font_color", ArtDirection.YELLOW)
	step.add_theme_stylebox_override("normal", ArtDirection.panel_style(ArtDirection.INK, ArtDirection.YELLOW, 2, 1))
	header.add_child(step)
	stack.add_child(header)
	stack.add_child(HSeparator.new())
	return stack


func _show_character_select() -> void:
	var stack := _selection_stack("CHARACTER SELECT // 캐릭터 선택", "먼저 생존 방식과 시작 카드군 범위를 결정할 캐릭터를 선택합니다", "STEP 01 / 03")
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	stack.add_child(body)

	var roster_panel := PanelContainer.new()
	roster_panel.name = "CharacterRoster"
	roster_panel.custom_minimum_size.x = 735
	roster_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	roster_panel.add_theme_stylebox_override("panel", ArtDirection.panel_style(Color(0.055, 0.055, 0.075, 0.96), ArtDirection.CYAN, 2, 1))
	body.add_child(roster_panel)
	var roster_margin := MarginContainer.new()
	roster_margin.add_theme_constant_override("margin_left", 14)
	roster_margin.add_theme_constant_override("margin_right", 14)
	roster_margin.add_theme_constant_override("margin_top", 14)
	roster_margin.add_theme_constant_override("margin_bottom", 14)
	roster_panel.add_child(roster_margin)
	var roster_stack := VBoxContainer.new()
	roster_stack.add_theme_constant_override("separation", 10)
	roster_margin.add_child(roster_stack)
	var roster_title := Label.new()
	roster_title.text = "CHARACTER ROSTER // 캐릭터 목록"
	roster_title.add_theme_font_size_override("font_size", 18)
	roster_title.add_theme_color_override("font_color", ArtDirection.CYAN)
	roster_stack.add_child(roster_title)
	var roster_scroll := ScrollContainer.new()
	roster_scroll.name = "CharacterSelectScroll"
	roster_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	roster_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	roster_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	roster_stack.add_child(roster_scroll)
	var grid := GridContainer.new()
	grid.name = "CharacterSelectGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	roster_scroll.add_child(grid)
	for character in all_characters:
		var entry := character
		var unlocked := unlocks.is_unlocked("characters", character.id)
		var style := "일반형" if character.style == CharacterDef.Style.GENERAL else "기믹형"
		var families: Array[String] = []
		for family in character.allowed_starting_families:
			families.append(_family_name(family))
		var tile := Button.new()
		tile.name = "CharacterSelectEntry_%s" % character.id
		tile.text = "%s
%s · %s · 콤보 %d칸
HP %.0f · 이동 %.0f · 방어 %.0f
%s" % [character.display_name, style, " / ".join(families), character.base_combo_slots, character.base_max_hp, character.base_move_speed, character.base_defense, character.description]
		tile.tooltip_text = character.description
		tile.custom_minimum_size = Vector2(340, 166)
		tile.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tile.disabled = not unlocked
		tile.add_theme_font_size_override("font_size", 15)
		tile.add_theme_color_override("font_color", ArtDirection.PAPER)
		var selected := selected_character != null and selected_character.id == character.id
		var accent := ArtDirection.YELLOW if selected else ArtDirection.CYAN
		tile.add_theme_stylebox_override("normal", ArtDirection.panel_style(Color(0.08, 0.06, 0.095, 0.98), accent, 3 if selected else 1, 1))
		tile.add_theme_stylebox_override("hover", ArtDirection.panel_style(Color(0.14, 0.07, 0.15, 0.99), ArtDirection.YELLOW, 3, 1))
		tile.pressed.connect(func(): _select_character(entry))
		grid.add_child(tile)

	var detail_panel := PanelContainer.new()
	detail_panel.name = "CharacterSelectDetail"
	detail_panel.custom_minimum_size.x = 455
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_stylebox_override("panel", ArtDirection.panel_style(ArtDirection.INK, ArtDirection.MAGENTA, 3, 1))
	body.add_child(detail_panel)
	var detail_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		detail_margin.add_theme_constant_override("margin_%s" % side, 14)
	detail_panel.add_child(detail_margin)
	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation", 8)
	detail_margin.add_child(detail)
	if selected_character:
		var portrait := TextureRect.new()
		portrait.name = "CharacterPortrait"
		portrait.texture = _character_portrait(selected_character.id)
		portrait.custom_minimum_size = Vector2(420, 300)
		portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		detail.add_child(portrait)
		var name_label := Label.new()
		name_label.text = selected_character.display_name
		name_label.add_theme_font_size_override("font_size", 26)
		name_label.add_theme_color_override("font_color", ArtDirection.YELLOW)
		detail.add_child(name_label)
		var info := Label.new()
		info.text = "%s · 기본 콤보 %d칸
HP %.0f · 이동 %.0f · 마력 %.0f · 방어 %.0f
선택 가능 카드군: %s" % ["일반형 캐릭터" if selected_character.style == CharacterDef.Style.GENERAL else "기믹형 캐릭터", selected_character.base_combo_slots, selected_character.base_max_hp, selected_character.base_move_speed, selected_character.base_magic_power, selected_character.base_defense, " / ".join(Array(selected_character.allowed_starting_families).map(func(id): return _family_name(id)))]
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_theme_font_size_override("font_size", 15)
		info.add_theme_color_override("font_color", ArtDirection.PAPER)
		detail.add_child(info)
		var confirm := _button("이 캐릭터 선택", _confirm_character_selection, 420)
		confirm.name = "ConfirmCharacterButton"
		confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		detail.add_child(confirm)
	var back := _button("메인 메뉴로", _cancel_start_to_main, 180)
	back.name = "CharacterBackButton"
	stack.add_child(back)


func _character_portrait(character_id: StringName) -> Texture2D:
	var path: String = {
		&"vanguard": "res://assets/concept/pilot_v2_2026-08-18/01_demon_vanguard_flat.png",
		&"conduit": "res://assets/concept/pilot_v2_2026-08-18/02_chibi_elemental_dash.png",
	}.get(character_id, "")
	return load(path) as Texture2D if path != "" else null


func _select_character(character: CharacterDef) -> void:
	selected_character = character
	selected_family = &""
	_show_character_select()


func _confirm_character_selection() -> void:
	if selected_character == null:
		return
	for family in selected_character.allowed_starting_families:
		if unlocks.is_unlocked("families", family):
			selected_family = family
			break
	flow.transition(RunFlowController.State.STARTING_FAMILY_SELECT)
	_show_family_select()


func _show_family_select() -> void:
	if selected_character == null:
		_back_to_character_select()
		return
	var stack := _selection_stack("CARD FAMILY SELECT // 시작 카드군", "카드군 전체 구성은 열람만 가능하며 시작 덱 4장은 자동 편성됩니다", "STEP 02 / 03")
	var family_title := Label.new()
	family_title.text = "사용 가능한 카드군 · 좌우 스크롤"
	family_title.add_theme_color_override("font_color", ArtDirection.CYAN)
	stack.add_child(family_title)
	var family_scroll := ScrollContainer.new()
	family_scroll.name = "FamilySelectHorizontalScroll"
	family_scroll.custom_minimum_size.y = 112
	family_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	family_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stack.add_child(family_scroll)
	var family_row := HBoxContainer.new()
	family_row.add_theme_constant_override("separation", 10)
	family_scroll.add_child(family_row)
	for family in selected_character.allowed_starting_families:
		if not unlocks.is_unlocked("families", family):
			continue
		var entry_id := family
		var count := 0
		for card in all_cards:
			if card.family_id == family:
				count += 1
		var tile := Button.new()
		tile.name = "FamilySelectEntry_%s" % family
		tile.text = "%s
%d CARDS · %s" % [_family_name(family), count, _family_playstyle(family)]
		tile.custom_minimum_size = Vector2(300, 92)
		tile.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tile.add_theme_font_size_override("font_size", 16)
		var selected := selected_family == family
		var accent := ArtDirection.YELLOW if selected else _card_family_color(family)
		tile.add_theme_stylebox_override("normal", ArtDirection.panel_style(Color(0.075, 0.055, 0.095, 0.98), accent, 3 if selected else 1, 1))
		tile.add_theme_stylebox_override("hover", ArtDirection.panel_style(Color(0.14, 0.07, 0.15, 0.99), ArtDirection.YELLOW, 3, 1))
		tile.pressed.connect(func(): _select_family(entry_id))
		family_row.add_child(tile)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	stack.add_child(body)
	var summary_panel := PanelContainer.new()
	summary_panel.name = "FamilySelectDetail"
	summary_panel.custom_minimum_size.x = 300
	summary_panel.add_theme_stylebox_override("panel", ArtDirection.panel_style(ArtDirection.INK, _card_family_color(selected_family), 3, 1))
	body.add_child(summary_panel)
	var summary_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		summary_margin.add_theme_constant_override("margin_%s" % side, 16)
	summary_panel.add_child(summary_margin)
	var summary := VBoxContainer.new()
	summary.add_theme_constant_override("separation", 10)
	summary_margin.add_child(summary)
	var emblem := Label.new()
	emblem.text = _family_name(selected_family)
	emblem.custom_minimum_size.y = 95
	emblem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emblem.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emblem.add_theme_font_size_override("font_size", 34)
	emblem.add_theme_color_override("font_color", _card_family_color(selected_family))
	emblem.add_theme_stylebox_override("normal", ArtDirection.panel_style(Color(0.11, 0.07, 0.12, 0.98), _card_family_color(selected_family), 2, 1))
	summary.add_child(emblem)
	var family_name := Label.new()
	family_name.text = "%s 카드군" % _family_name(selected_family)
	family_name.add_theme_font_size_override("font_size", 23)
	family_name.add_theme_color_override("font_color", ArtDirection.YELLOW)
	summary.add_child(family_name)
	var family_desc := Label.new()
	family_desc.text = _family_description(selected_family)
	family_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	family_desc.add_theme_font_size_override("font_size", 15)
	family_desc.add_theme_color_override("font_color", ArtDirection.PAPER)
	summary.add_child(family_desc)
	var notice := Label.new()
	notice.text = "START RULE
일반 3장 + 첫 희귀 카드 1장
초기 덱 편집 및 정제 불가"
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.add_theme_color_override("font_color", ArtDirection.CYAN)
	summary.add_child(notice)
	var confirm := _button("이 카드군 선택", _confirm_family_selection, 270)
	confirm.name = "ConfirmFamilyButton"
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_child(confirm)

	var cards_panel := PanelContainer.new()
	cards_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_panel.add_theme_stylebox_override("panel", ArtDirection.panel_style(Color(0.045, 0.045, 0.065, 0.97), ArtDirection.MAGENTA, 2, 1))
	body.add_child(cards_panel)
	var cards_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		cards_margin.add_theme_constant_override("margin_%s" % side, 12)
	cards_panel.add_child(cards_margin)
	var cards_stack := VBoxContainer.new()
	cards_margin.add_child(cards_stack)
	var cards_title := Label.new()
	cards_title.text = "%s 카드 전체 구성 · 세로 스크롤" % _family_name(selected_family)
	cards_title.add_theme_font_size_override("font_size", 18)
	cards_title.add_theme_color_override("font_color", ArtDirection.MAGENTA)
	cards_stack.add_child(cards_title)
	var card_scroll := ScrollContainer.new()
	card_scroll.name = "FamilyCardVerticalScroll"
	card_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	cards_stack.add_child(card_scroll)
	var card_grid := GridContainer.new()
	card_grid.name = "FamilyCardPreviewGrid"
	card_grid.columns = 2
	card_grid.add_theme_constant_override("h_separation", 8)
	card_grid.add_theme_constant_override("v_separation", 8)
	card_scroll.add_child(card_grid)
	var starting_ids: Array[StringName] = []
	var preview_deck := ContentFactory.starting_deck(selected_family, all_cards)
	for instance in preview_deck.cards:
		starting_ids.append(instance.card_def.id)
	for card in all_cards:
		if card.family_id != selected_family:
			continue
		var card_panel := PanelContainer.new()
		card_panel.name = "FamilyCardPreview_%s" % card.id
		card_panel.custom_minimum_size = Vector2(390, 116)
		var accent := ArtDirection.YELLOW if card.id in starting_ids else _card_family_color(card.family_id)
		card_panel.add_theme_stylebox_override("panel", ArtDirection.panel_style(Color(0.085, 0.06, 0.1, 0.98), accent, 2 if card.id in starting_ids else 1, 1))
		var card_margin := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			card_margin.add_theme_constant_override("margin_%s" % side, 10)
		card_panel.add_child(card_margin)
		var card_text := Label.new()
		card_text.text = "%s%s
%s · %.1fs · %s
%s" % ["START // " if card.id in starting_ids else "", card.display_name, _rarity_name(card.rarity), card.execution_interval, " · ".join(card.targeting_labels()), card.description]
		card_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_text.add_theme_font_size_override("font_size", 14)
		card_text.add_theme_color_override("font_color", ArtDirection.PAPER)
		card_margin.add_child(card_text)
		card_grid.add_child(card_panel)
	var back := _button("캐릭터 선택으로", _back_to_character_select, 200)
	back.name = "FamilyBackButton"
	stack.add_child(back)


func _select_family(family: StringName) -> void:
	if selected_character == null or not selected_character.allows_family(family):
		return
	selected_family = family
	_show_family_select()


func _family_playstyle(family: StringName) -> String:
	return {
		&"sword": "근접·처형·참격",
		&"spear": "직선·관통·사거리",
		&"blunt": "충격·넉백·소환",
		&"fire": "연소·폭발·장판",
		&"water": "젖음·제어·보호",
		&"poison": "중독·확산·설치",
	}.get(family, "")


func _family_description(family: StringName) -> String:
	return {
		&"sword": "빠른 근접 참격과 딸피 우선 공격으로 전열을 정리하는 카드군입니다.",
		&"spear": "긴 직선 사거리와 관통을 이용해 정렬된 적 무리를 꿰뚫습니다.",
		&"blunt": "강한 넉백과 충격파, 로봇·골렘 소환으로 공간을 장악합니다.",
		&"fire": "연소를 누적하고 폭발과 대형 장판으로 밀집 지역을 태웁니다.",
		&"water": "젖음과 이동 제어, 보호막을 조합해 안정적으로 반응을 준비합니다.",
		&"poison": "중독 스택을 전파하고 설치물과 폭발로 장기전을 강화합니다.",
	}.get(family, "")


func _confirm_family_selection() -> void:
	if selected_family == &"":
		return
	selected_map = null
	for map in all_maps:
		if unlocks.is_unlocked("maps", map.id):
			selected_map = map
			break
	flow.transition(RunFlowController.State.MAP_SELECT)
	_show_map_select()


func _show_map_select(_legacy_endless := false) -> void:
	var stack := _selection_stack("MAP SELECT // 생존 맵", "마지막으로 전장 정보와 출현 로스터를 확인한 뒤 생존을 시작합니다", "STEP 03 / 03")
	var map_title := Label.new()
	map_title.text = "생존 맵 목록 · 좌우 스크롤"
	map_title.add_theme_color_override("font_color", ArtDirection.CYAN)
	stack.add_child(map_title)
	var map_scroll := ScrollContainer.new()
	map_scroll.name = "MapSelectHorizontalScroll"
	map_scroll.custom_minimum_size.y = 104
	map_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	map_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stack.add_child(map_scroll)
	var map_row := HBoxContainer.new()
	map_row.add_theme_constant_override("separation", 10)
	map_scroll.add_child(map_row)
	for map in all_maps:
		var entry := map
		var tile := Button.new()
		tile.name = "MapSelectEntry_%s" % map.id
		tile.text = "%s
%s" % [map.display_name, "다각형 생존 전장" if map.arena_shape == MapDef.ArenaShape.POLYGON else "원형 생존 전장"]
		tile.custom_minimum_size = Vector2(330, 84)
		tile.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tile.disabled = not unlocks.is_unlocked("maps", map.id)
		var selected := selected_map != null and selected_map.id == map.id
		var accent := ArtDirection.YELLOW if selected else ArtDirection.CYAN
		tile.add_theme_stylebox_override("normal", ArtDirection.panel_style(Color(0.075, 0.055, 0.095, 0.98), accent, 3 if selected else 1, 1))
		tile.add_theme_stylebox_override("hover", ArtDirection.panel_style(Color(0.14, 0.07, 0.15, 0.99), ArtDirection.YELLOW, 3, 1))
		tile.pressed.connect(func(): _select_map(entry))
		map_row.add_child(tile)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	stack.add_child(body)
	if selected_map:
		var info_panel := PanelContainer.new()
		info_panel.name = "MapSelectDetail"
		info_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		info_panel.add_theme_stylebox_override("panel", ArtDirection.panel_style(ArtDirection.INK, ArtDirection.MAGENTA, 3, 1))
		body.add_child(info_panel)
		var info_margin := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			info_margin.add_theme_constant_override("margin_%s" % side, 16)
		info_panel.add_child(info_margin)
		var info := VBoxContainer.new()
		info.add_theme_constant_override("separation", 9)
		info_margin.add_child(info)
		var name_label := Label.new()
		name_label.text = selected_map.display_name
		name_label.add_theme_font_size_override("font_size", 27)
		name_label.add_theme_color_override("font_color", ArtDirection.YELLOW)
		info.add_child(name_label)
		var description := Label.new()
		description.text = selected_map.description
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_font_size_override("font_size", 16)
		description.add_theme_color_override("font_color", ArtDirection.PAPER)
		info.add_child(description)
		var rules := Label.new()
		rules.text = "SURVIVAL RULE
%s" % selected_map.survival_rules
		rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rules.add_theme_color_override("font_color", ArtDirection.CYAN)
		info.add_child(rules)
		info.add_child(HSeparator.new())
		var roster_title := Label.new()
		roster_title.text = "출현 적 / 보스"
		roster_title.add_theme_font_size_override("font_size", 19)
		roster_title.add_theme_color_override("font_color", ArtDirection.MAGENTA)
		info.add_child(roster_title)
		var roster_scroll := ScrollContainer.new()
		roster_scroll.name = "MapEnemyRosterScroll"
		roster_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		roster_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		roster_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		info.add_child(roster_scroll)
		var roster := VBoxContainer.new()
		roster.add_theme_constant_override("separation", 5)
		roster_scroll.add_child(roster)
		for enemy in ContentFactory.all_enemies():
			var enemy_label := Label.new()
			enemy_label.text = "%s  ·  %s / %s  ·  %s" % [enemy.display_name, _enemy_rank_name(enemy.rank), _enemy_role_name(enemy.role), _enemy_spawn_text(enemy)]
			enemy_label.add_theme_color_override("font_color", _enemy_rank_color(enemy.rank))
			roster.add_child(enemy_label)
		var art_panel := PanelContainer.new()
		art_panel.custom_minimum_size.x = 470
		art_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		art_panel.add_theme_stylebox_override("panel", ArtDirection.panel_style(Color(0.04, 0.045, 0.06, 0.98), ArtDirection.CYAN, 3, 1))
		body.add_child(art_panel)
		var art_margin := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			art_margin.add_theme_constant_override("margin_%s" % side, 12)
		art_panel.add_child(art_margin)
		var art_stack := VBoxContainer.new()
		art_stack.add_theme_constant_override("separation", 10)
		art_margin.add_child(art_stack)
		var art := TextureRect.new()
		art.name = "MapPreviewImage"
		art.texture = _map_preview_texture(selected_map.id)
		art.custom_minimum_size = Vector2(440, 310)
		art.size_flags_vertical = Control.SIZE_EXPAND_FILL
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art_stack.add_child(art)
		var loadout := Label.new()
		loadout.text = "%s // %s
시작 카드군: %s · 시작 덱 4장 · 자동 콤보 편성" % [selected_character.display_name, selected_map.display_name, _family_name(selected_family)]
		loadout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		loadout.add_theme_color_override("font_color", ArtDirection.PAPER)
		art_stack.add_child(loadout)
		var confirm := _button("이 맵에서 생존 시작", _confirm_map_selection, 440)
		confirm.name = "ConfirmMapButton"
		confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		art_stack.add_child(confirm)
	var back := _button("카드군 선택으로", _back_to_family_select, 200)
	back.name = "MapBackButton"
	stack.add_child(back)


func _map_preview_texture(map_id: StringName) -> Texture2D:
	if map_id == &"foundry":
		return load("res://assets/arena_foundry.png") as Texture2D
	return null


func _select_map(map: MapDef, _legacy_endless := false) -> void:
	selected_map = map
	_show_map_select()


func _confirm_map_selection() -> void:
	if selected_map == null or selected_family == &"":
		return
	_start_run(selected_family)


func _cancel_start_to_main() -> void:
	flow.transition(RunFlowController.State.MAIN_MENU)
	_show_main_menu()


func _back_to_character_select() -> void:
	flow.transition(RunFlowController.State.CHARACTER_SELECT)
	_show_character_select()


func _back_to_family_select() -> void:
	flow.transition(RunFlowController.State.STARTING_FAMILY_SELECT)
	_show_family_select()


func _start_run(family: StringName) -> void:
	session = RunSession.create(int(Time.get_ticks_msec()), selected_map.id, selected_character.id, family, RunSession.Mode.SURVIVOR)
	run_rng = RunRng.new(session.seed)
	deck = ContentFactory.starting_deck(family, all_cards)
	cycle = ContentFactory.default_cycle(deck, selected_character.combo_slot_count(session.combo_slot_modifier))
	run_map = null
	flow.attach_session(session)
	flow.transition(RunFlowController.State.RUN_MAP)
	_start_survivor_battle()

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
	var source_deck := arena.queued_survivor_deck if arena.queued_survivor_deck != null else arena.deck
	var source_cycle := arena.queued_survivor_cycle if arena.queued_survivor_cycle != null else arena.cycle
	deck = source_deck.duplicate_state()
	cycle = CycleState.from_dict(source_cycle.to_dict())
	get_tree().paused = true
	survivor_reward_claimed = false
	survivor_level_stage = SurvivorLevelStage.REWARD
	survivor_reward_view = "acquire"
	survivor_level_action = ""
	survivor_card_rerolls_left = 1
	survivor_card_offers = RewardOfferService.create_offer(all_cards, deck, run_rng, 3)
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
	stack.add_theme_constant_override("separation", 9)
	margin.add_child(stack)
	var title := Label.new()
	title.text = "LEVEL %02d // CHOOSE ONE" % level if survivor_level_stage == SurvivorLevelStage.REWARD else "LEVEL %02d // DECK REFINEMENT" % level
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", ArtDirection.YELLOW)
	stack.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "카드 획득·강화·유물·삭제 중 행동 하나만 선택 · XP %.0f / %.0f" % [xp, next_xp] if survivor_level_stage == SurvivorLevelStage.REWARD else "카드 순서와 콤보 배치만 정리 · 변경은 기존 콤보 회전과 남은 딜레이 종료 후 적용"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", ArtDirection.CYAN)
	stack.add_child(subtitle)
	if survivor_level_stage == SurvivorLevelStage.REWARD:
		_build_survivor_reward_screen(stack, arena, level, xp, next_xp)
	else:
		_build_survivor_refine_screen(stack, arena, level, xp, next_xp)


func _build_survivor_reward_screen(stack: VBoxContainer, arena: BattleArena, level: int, xp: float, next_xp: float) -> void:
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	var acquire_tab := _button("카드 획득", func(): survivor_reward_view = "acquire"; _show_survivor_level_overlay(arena, level, xp, next_xp), 220)
	acquire_tab.name = "SurvivorAcquireModeButton"
	acquire_tab.disabled = survivor_reward_view == "acquire"
	tabs.add_child(acquire_tab)
	var delete_tab := _button("카드 1장 삭제", func(): survivor_reward_view = "delete"; _show_survivor_level_overlay(arena, level, xp, next_xp), 220)
	delete_tab.name = "SurvivorDeleteModeButton"
	delete_tab.disabled = survivor_reward_view == "delete" or deck.cards.size() <= cycle.combos.size()
	tabs.add_child(delete_tab)
	var rule := Label.new()
	rule.text = "선택 완료 후 다른 보상 행동은 잠깁니다"
	rule.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rule.add_theme_color_override("font_color", ArtDirection.PAPER_DIM)
	tabs.add_child(rule)
	stack.add_child(tabs)
	if survivor_reward_view == "delete":
		_build_survivor_delete_choices(stack, arena, level, xp, next_xp)
		return
	var heading := Label.new()
	heading.text = "카드 후보 · 최대 1장 획득"
	heading.add_theme_font_size_override("font_size", 19)
	heading.add_theme_color_override("font_color", ArtDirection.PAPER)
	stack.add_child(heading)
	var offers := HBoxContainer.new()
	offers.add_theme_constant_override("separation", 12)
	for offer_index in range(survivor_card_offers.size()):
		var card_def := survivor_card_offers[offer_index]
		var card_button := _button("%s\n%s · %s · %.1fs\n%s\n%s" % [card_def.display_name, _family_name(card_def.family_id), _rarity_name(card_def.rarity), card_def.execution_interval, " · ".join(card_def.targeting_labels()), card_def.description], func(): _survivor_take_card(arena, card_def, level, xp, next_xp), 360)
		card_button.name = "SurvivorCardOffer_%d" % offer_index
		card_button.custom_minimum_size.y = 190
		card_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		offers.add_child(card_button)
	stack.add_child(offers)
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 10)
	var reroll := _button("REROLL · 남은 %d" % survivor_card_rerolls_left, func(): _survivor_reroll_cards(arena, level, xp, next_xp), 230)
	reroll.name = "SurvivorRerollButton"
	reroll.disabled = survivor_card_rerolls_left <= 0
	controls.add_child(reroll)
	var upgrade_card := _survivor_upgrade_candidate(level)
	if upgrade_card != null:
		var upgrade := _button("카드 강화\n%s Lv.%d → Lv.%d" % [upgrade_card.display_name, upgrade_card.upgrade_level, upgrade_card.upgrade_level + 1], func(): _survivor_upgrade_card(arena, upgrade_card.instance_id, level, xp, next_xp), 260)
		upgrade.name = "SurvivorUpgradeReward"
		controls.add_child(upgrade)
	var relic := _survivor_next_relic(level)
	if not relic.is_empty():
		var relic_button := _button("유물 획득\n%s" % relic["name"], func(): _survivor_take_relic(arena, relic, level, xp, next_xp), 250)
		relic_button.name = "SurvivorRelicReward"
		controls.add_child(relic_button)
	var skip := _button("행동 건너뛰기", func(): _survivor_skip_action(arena, level, xp, next_xp), 200)
	skip.name = "SurvivorSkipReward"
	controls.add_child(skip)
	stack.add_child(controls)


func _build_survivor_delete_choices(stack: VBoxContainer, arena: BattleArena, level: int, xp: float, next_xp: float) -> void:
	var heading := Label.new()
	heading.text = "삭제할 카드 선택 · 최대 1장"
	heading.add_theme_font_size_override("font_size", 19)
	heading.add_theme_color_override("font_color", ArtDirection.DANGER)
	stack.add_child(heading)
	var scroll := ScrollContainer.new()
	scroll.name = "SurvivorDeleteChoiceScroll"
	scroll.custom_minimum_size.y = 480
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	stack.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 7)
	scroll.add_child(list)
	for card in deck.cards:
		var delete_card := card
		var button := _button("삭제 // %s\n%s" % [card.display_name, _card_summary(card)], func(): _survivor_delete_card(arena, delete_card.instance_id, level, xp, next_xp), 1090)
		button.name = "SurvivorDeleteChoice_%s" % card.instance_id
		button.custom_minimum_size.y = 70
		button.disabled = deck.cards.size() <= cycle.combos.size() or card.locked or card.undeletable
		list.add_child(button)


func _build_survivor_refine_screen(stack: VBoxContainer, arena: BattleArena, _level: int, _xp: float, _next_xp: float) -> void:
	if cycle.combos.is_empty():
		_ensure_combo(0)
	var action := Label.new()
	action.text = "선택 완료: %s · %d개 콤보 슬롯은 %s의 기본 구성" % [_survivor_action_label(), cycle.combos.size(), selected_character.display_name]
	action.add_theme_font_size_override("font_size", 17)
	action.add_theme_color_override("font_color", ArtDirection.CYAN)
	stack.add_child(action)
	var scroll := ScrollContainer.new()
	scroll.name = "SurvivorComboScroll"
	scroll.custom_minimum_size.y = 470
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	stack.add_child(scroll)
	var board := HBoxContainer.new()
	board.name = "SurvivorComboBoard"
	board.add_theme_constant_override("separation", 12)
	scroll.add_child(board)
	for combo_index in range(cycle.combos.size()):
		var combo: ComboState = cycle.combos[combo_index]
		var column := VBoxContainer.new()
		column.custom_minimum_size.x = 260
		var heading := Label.new()
		heading.text = "COMBO %s\n%d장 · %.1f초" % [_combo_label(combo_index), combo.card_instance_ids.size(), _combo_duration(combo)]
		heading.add_theme_font_size_override("font_size", 17)
		heading.add_theme_color_override("font_color", ArtDirection.CYAN)
		column.add_child(heading)
		var zone := ComboDropZone.new()
		zone.configure(combo_index)
		zone.add_theme_constant_override("separation", 5)
		zone.card_dropped.connect(func(card_id, target_combo, target_index): _survivor_drop_card(arena, card_id, target_combo, target_index, _level, _xp, _next_xp))
		column.add_child(zone)
		for card_index in range(combo.card_instance_ids.size()):
			var card := deck.get_card(combo.card_instance_ids[card_index])
			if card == null:
				continue
			var drag_card := ComboDragCard.new()
			drag_card.configure(card.instance_id, combo_index, card_index, _card_tile_text(card, card_index + 1))
			drag_card.custom_minimum_size = Vector2(250, 82)
			drag_card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			drag_card.card_dropped.connect(func(dropped_id, target_combo, target_index): _survivor_drop_card(arena, dropped_id, target_combo, target_index, _level, _xp, _next_xp))
			zone.add_child(drag_card)
		if combo.card_instance_ids.is_empty():
			var empty := Label.new()
			empty.text = "DROP CARD\n전투 재개 전 한 장 이상 배치"
			empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty.custom_minimum_size.y = 82
			empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
			empty.add_theme_color_override("font_color", ArtDirection.YELLOW)
			zone.add_child(empty)
		board.add_child(column)
	var validation := ComboValidator.validate(deck, cycle)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 14)
	var state_label := Label.new()
	state_label.text = "VALID // 카드 배치 완료" if validation.valid else "INVALID // 모든 고정 콤보 슬롯에 한 장 이상 배치하세요"
	state_label.custom_minimum_size.x = 790
	state_label.add_theme_font_size_override("font_size", 15)
	state_label.add_theme_color_override("font_color", ArtDirection.CYAN if validation.valid else ArtDirection.DANGER)
	footer.add_child(state_label)
	var resume := _button("정제 완료 · 전투 재개", func(): _resume_survivor(arena), 300)
	resume.name = "SurvivorResumeButton"
	resume.disabled = not validation.valid
	footer.add_child(resume)
	stack.add_child(footer)


func _survivor_reroll_cards(arena: BattleArena, level: int, xp: float, next_xp: float) -> void:
	if survivor_reward_claimed or survivor_reward_view != "acquire" or survivor_card_rerolls_left <= 0:
		return
	var previous_ids: Array[StringName] = []
	for card in survivor_card_offers:
		previous_ids.append(card.id)
	var filtered_pool: Array[CardDef] = []
	for card in all_cards:
		if not previous_ids.has(card.id):
			filtered_pool.append(card)
	survivor_card_offers = RewardOfferService.create_offer(filtered_pool if filtered_pool.size() >= 3 else all_cards, deck, run_rng, 3)
	survivor_card_rerolls_left -= 1
	_show_survivor_level_overlay(arena, level, xp, next_xp)


func _survivor_skip_action(arena: BattleArena, level: int, xp: float, next_xp: float) -> void:
	if survivor_reward_claimed:
		return
	survivor_reward_claimed = true
	survivor_level_action = "skip"
	survivor_level_stage = SurvivorLevelStage.REFINE
	_show_survivor_level_overlay(arena, level, xp, next_xp)


func _survivor_action_label() -> String:
	match survivor_level_action:
		"acquire": return "카드 1장 획득"
		"delete": return "카드 1장 삭제"
		"upgrade": return "카드 1장 강화"
		"relic": return "유물 1개 획득"
		_: return "행동 건너뛰기"

func _survivor_best_lane(_card_def: CardDef) -> int:
	return _shortest_combo_index()


func _survivor_take_card(arena: BattleArena, card_def: CardDef, level: int, xp: float, next_xp: float) -> void:
	if survivor_reward_claimed or survivor_level_stage != SurvivorLevelStage.REWARD or not survivor_card_offers.has(card_def):
		return
	var lane := _survivor_best_lane(card_def)
	if lane < 0:
		return
	var instance := CardInstance.create(card_def, &"survivor_level")
	if not deck.add_card(instance):
		return
	_ensure_combo(lane).card_instance_ids.append(instance.instance_id)
	_normalize_cycle(false)
	survivor_reward_claimed = true
	survivor_level_action = "acquire"
	survivor_level_stage = SurvivorLevelStage.REFINE
	_show_survivor_level_overlay(arena, level, xp, next_xp)

func _survivor_next_relic(level: int) -> Dictionary:
	var available: Array[Dictionary] = []
	for relic in ContentFactory.survivor_relics():
		if not session.relic_ids.has(StringName(relic.get("id", ""))):
			available.append(relic)
	if available.is_empty():
		return {}
	return available[level % available.size()]


func _survivor_upgrade_candidate(level: int) -> CardInstance:
	if deck == null or deck.cards.is_empty():
		return null
	var candidates: Array[CardInstance] = []
	for card in deck.cards:
		if card.upgrade_level < CardUpgradeService.MAX_LEVEL:
			candidates.append(card)
	if candidates.is_empty():
		return null
	return candidates[(maxi(1, level) - 1) % candidates.size()]


func _survivor_upgrade_card(arena: BattleArena, card_id: StringName, level: int, xp: float, next_xp: float) -> void:
	if survivor_reward_claimed or survivor_level_stage != SurvivorLevelStage.REWARD:
		return
	var card := deck.get_card(card_id)
	if not CardUpgradeService.upgrade(card):
		return
	survivor_reward_claimed = true
	survivor_level_action = "upgrade"
	survivor_level_stage = SurvivorLevelStage.REFINE
	_show_survivor_level_overlay(arena, level, xp, next_xp)

func _survivor_take_relic(arena: BattleArena, relic: Dictionary, level: int, xp: float, next_xp: float) -> void:
	if survivor_reward_claimed or survivor_level_stage != SurvivorLevelStage.REWARD:
		return
	var relic_id := StringName(relic.get("id", ""))
	if relic_id == &"" or session.relic_ids.has(relic_id):
		return
	session.relic_ids.append(relic_id)
	arena.apply_survivor_relic(relic)
	survivor_reward_claimed = true
	survivor_level_action = "relic"
	survivor_level_stage = SurvivorLevelStage.REFINE
	_show_survivor_level_overlay(arena, level, xp, next_xp)

func _survivor_drop_card(arena: BattleArena, card_id: StringName, target_combo_index: int, target_card_index: int, level: int, xp: float, next_xp: float) -> void:
	if survivor_level_stage != SurvivorLevelStage.REFINE or target_combo_index < 0:
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
	_show_survivor_level_overlay(arena, level, xp, next_xp)

func _survivor_delete_card(arena: BattleArena, card_id: StringName, level: int, xp: float, next_xp: float) -> void:
	if survivor_reward_claimed or survivor_level_stage != SurvivorLevelStage.REWARD or survivor_reward_view != "delete":
		return
	if deck.cards.size() <= cycle.combos.size():
		return
	var card := deck.get_card(card_id)
	if card == null or card.locked or card.undeletable:
		return
	_remove_card_from_cycle(card_id)
	deck.remove_card(card_id)
	_normalize_cycle(false)
	survivor_reward_claimed = true
	survivor_level_action = "delete"
	survivor_level_stage = SurvivorLevelStage.REFINE
	_show_survivor_level_overlay(arena, level, xp, next_xp)

func _resume_survivor(arena: BattleArena) -> void:
	if not survivor_reward_claimed or not ComboValidator.validate(deck, cycle)["valid"]:
		return
	if not arena.queue_survivor_cycle(deck, cycle):
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
	survivor_arena.name = "SurvivorArena"
	root_control.add_child(survivor_arena)
	survivor_arena.completed.connect(func(success, summary): call_deferred(&"_on_survivor_completed", success, summary))
	survivor_arena.survivor_level_up_requested.connect(func(level, xp, next_xp): _on_survivor_level_up(survivor_arena, level, xp, next_xp))
	survivor_arena.survivor_currency_changed.connect(_on_survivor_currency_changed)
	survivor_arena.initialize_survivor(selected_character, deck, cycle, run_rng, session.currency)


func _on_survivor_currency_changed(_amount: int, total: int) -> void:
	if session:
		session.currency = total


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
	var survivor_result := session != null and session.mode == RunSession.Mode.SURVIVOR
	var title := "생존 기록" if survivor_result else "런 클리어" if success else "런 종료"
	var subtitle := "무한 생존 결과 · 덱과 콤보를 정비해 다음 기록에 도전하세요" if survivor_result else "보스 검증을 통과했습니다" if success else "빌드를 정비하고 다시 도전하세요"
	var stack := _screen_stack(title, subtitle)
	var report := Label.new()
	if survivor_result:
		var survived := int(summary.get("elapsed", 0.0))
		report.text = "모드: 무한 생존\n맵: %s\n캐릭터: %s\n카드군: %s\n생존 시간: %02d:%02d\n도달 레벨: %d\n덱: %d장\n유물: %d개\n수집 재화: %d\n처치: %d\n종료 사유: %s" % [selected_map.display_name, selected_character.display_name, _family_name(session.starting_family_id), survived / 60, survived % 60, int(summary.get("level", 1)), deck.cards.size(), int(summary.get("relics", 0)), int(summary.get("currency", session.currency)), int(summary.get("kills", 0)), summary.get("reason", "체력 0")]
	else:
		report.text = "모드: 레거시 런\n맵: %s\n캐릭터: %s\n카드군: %s\n덱: %d장\n재화: %d\n처치: %d\n종료 사유: %s" % [selected_map.display_name, selected_character.display_name, _family_name(session.starting_family_id), deck.cards.size(), session.currency, int(summary.get("kills", 0)), summary.get("reason", "보스 처치" if success else "체력 0")]
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
