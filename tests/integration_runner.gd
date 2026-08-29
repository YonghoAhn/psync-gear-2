extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred(&"_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	var packed := load("res://scenes/Main.tscn") as PackedScene
	_expect(packed != null, "Main scene must load")
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	_expect(game.all_cards.size() == 48, "game root must register all 48 card definitions")
	_expect(ContentFactory.all_enemies().size() == 12, "enemy roster must expose 8 mobs, 3 named enemies, and 1 boss")

	var main_menu_buttons: Array[Node] = game.root_control.find_children("*", "Button", true, false)
	var menu_texts: Array[String] = []
	for button_node in main_menu_buttons:
		var menu_button := button_node as Button
		if menu_button:
			menu_texts.append(menu_button.text)
	_expect("게임 시작 · 무한 생존" in menu_texts, "main menu must promote infinite survival to the primary start action")
	_expect(menu_texts.any(func(text): return text.begins_with("카드 도감")), "main menu must expose the card archive")
	_expect(menu_texts.any(func(text): return text.begins_with("적 도감")), "main menu must expose the enemy archive")
	_expect(menu_texts.any(func(text): return text.begins_with("맵 도감")), "main menu must expose the map archive")
	_expect(not menu_texts.any(func(text): return "노드 런" in text or "노드 무한" in text or "A/B" in text), "main menu must not expose legacy node-run or A/B entries")

	game._open_card_codex()
	await process_frame
	_expect(game.root_control.find_children("CardCodexCard_*", "Button", true, false).size() == 48, "card archive must display every registered card")
	var card_scroll := game.root_control.find_child("CardCodexScroll", true, false) as ScrollContainer
	_expect(card_scroll != null and card_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "card archive collection must be vertically scrollable")
	_expect(game.root_control.find_child("CardCodexDetail", true, false) != null, "card archive must display a selected-card detail panel")
	game._set_codex_family_filter(1)
	await process_frame
	_expect(game.root_control.find_children("CardCodexCard_*", "Button", true, false).size() == 8, "each card-family filter must expose its eight-card set")

	game._open_enemy_codex()
	await process_frame
	_expect(game.root_control.find_children("EnemyCodexEntry_*", "Button", true, false).size() == 12, "enemy archive must display every live combat enemy")
	var enemy_scroll := game.root_control.find_child("EnemyCodexScroll", true, false) as ScrollContainer
	_expect(enemy_scroll != null and enemy_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "enemy archive must be vertically scrollable")
	_expect(game.root_control.find_child("EnemyCodexDetail", true, false) != null, "enemy archive must display a selected-enemy detail panel")
	game._set_enemy_codex_rank_filter(1)
	await process_frame
	_expect(game.root_control.find_children("EnemyCodexEntry_*", "Button", true, false).size() == 8, "mob filter must expose eight standard enemies")
	game._set_enemy_codex_rank_filter(2)
	await process_frame
	_expect(game.root_control.find_children("EnemyCodexEntry_*", "Button", true, false).size() == 3, "named filter must expose three named enemies")
	game._set_enemy_codex_rank_filter(3)
	await process_frame
	_expect(game.root_control.find_children("EnemyCodexEntry_*", "Button", true, false).size() == 1, "boss filter must expose the foundry boss")

	game._open_map_codex()
	await process_frame
	_expect(game.root_control.find_children("MapCodexEntry_*", "Button", true, false).size() == game.all_maps.size(), "map archive must display every registered survival map")
	_expect(game.root_control.find_child("MapCodexDetail", true, false) != null, "map archive must display the selected map detail")
	_expect(not game.all_maps[0].description.is_empty() and not game.all_maps[0].survival_rules.is_empty(), "map definitions must include archive description and survival rules")
	_expect(not game.all_maps[0].environment_features.is_empty() and not game.all_maps[0].enemy_roster_summary.is_empty(), "map definitions must expose environment and roster data")

	game._show_main_menu()
	game._begin_survivor()
	await process_frame
	_expect(game.flow.state == RunFlowController.State.CHARACTER_SELECT, "new game must open character selection first")
	_expect(game.root_control.find_children("CharacterSelectEntry_*", "Button", true, false).size() == game.all_characters.size(), "character screen must expose a grid entry for every character")
	_expect(game.root_control.find_child("CharacterPortrait", true, false) != null, "character screen must display the selected portrait")
	_expect(game.root_control.find_child("CharacterSelectScroll", true, false) is ScrollContainer, "character roster must be vertically scrollable")
	game._select_character(game.all_characters[0])
	game._confirm_character_selection()
	await process_frame
	_expect(game.flow.state == RunFlowController.State.STARTING_FAMILY_SELECT, "confirmed character must advance to card-family selection")
	_expect(game.root_control.find_children("FamilySelectEntry_*", "Button", true, false).size() == game.selected_character.allowed_starting_families.size(), "family screen must expose only the selected character's allowed families")
	var family_horizontal := game.root_control.find_child("FamilySelectHorizontalScroll", true, false) as ScrollContainer
	var family_vertical := game.root_control.find_child("FamilyCardVerticalScroll", true, false) as ScrollContainer
	_expect(family_horizontal != null and family_horizontal.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "card-family list must scroll horizontally")
	_expect(family_vertical != null and family_vertical.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "selected family's cards must scroll vertically")
	_expect(game.root_control.find_children("FamilyCardPreview_*", "PanelContainer", true, false).size() == 8, "family screen must preview all eight cards without editing them")
	_expect(game.root_control.find_children("*", "ComboDragCard", true, false).is_empty(), "start flow must not expose deck refinement controls")
	var family: StringName = game.selected_character.allowed_starting_families[0]
	game._select_family(family)
	game._confirm_family_selection()
	await process_frame
	_expect(game.flow.state == RunFlowController.State.MAP_SELECT, "confirmed family must advance to map selection last")
	_expect(game.root_control.find_children("MapSelectEntry_*", "Button", true, false).size() == game.all_maps.size(), "map screen must expose every available map in a horizontal list")
	_expect(game.root_control.find_child("MapPreviewImage", true, false) != null, "map screen must display the selected map image")
	_expect(game.root_control.find_child("MapEnemyRosterScroll", true, false) != null, "map screen must display its enemy and boss roster")
	_expect(game.deck == null, "starting deck must not be created or refined before final map confirmation")
	game._confirm_map_selection()
	await process_frame
	_expect(game.session != null and game.session.mode == RunSession.Mode.SURVIVOR, "primary start flow must create an infinite-survival session")
	_expect(game.run_map == null, "primary start flow must not generate a node map")
	_expect(ComboValidator.validate(game.deck, game.cycle)["valid"], "primary start flow must create a valid automatic cycle")
	_expect(game.cycle.combos.size() == game.selected_character.combo_slot_count(game.session.combo_slot_modifier), "selected character must determine the starting combo slot count")
	_expect(game.flow.state == RunFlowController.State.ENCOUNTER, "final map confirmation must enter infinite survival immediately")
	var arena: BattleArena = game.survivor_arena
	_expect(arena != null and arena.survivor_mode, "primary start flow must instantiate a survivor BattleArena")
	if arena:
		_expect(arena.camera != null and arena.camera.enabled and arena.camera.get_parent() == arena.player, "battle camera must follow the player")
		_expect(arena.spawn_timer >= 3.0, "survival enemy wave must have an initial grace period")
		_expect(arena.get_tree().get_nodes_in_group(&"spawn_warning").size() == 3, "initial survival enemies must show one-second spawn warnings")
		_expect(arena.hud != null and arena.hud.xp_bar.visible, "survivor HUD must expose XP progression")
		_expect(arena.hud.xp_bar.anchor_left == 0.0 and arena.hud.xp_bar.anchor_right == 1.0 and arena.hud.xp_bar.offset_left == 0.0 and arena.hud.xp_bar.offset_right == 0.0, "XP bar must be anchored full-width at the top edge")
		_expect(arena.player.world_health_bar != null and arena.player.world_health_bar.get_parent() == arena.player and arena.hud.hp_bar == arena.player.world_health_bar, "HP bar must be a world-space child that follows the player")
		_expect(arena.hud.currency_label != null and arena.hud.currency_label.position.x > arena.hud.relic_rail.position.x, "currency must appear beside the upper-left relic rail")
		_expect(arena.hud.timer_label != null and arena.hud.timer_label.position.x > 1000.0, "survival timer must occupy the right side of the HUD")
		_expect(not arena.hud.consumable_panel.visible and not arena.player.consumables_enabled, "consumables must remain disabled and hidden")
		var currency_enemy := BattleEnemy.new()
		arena._on_enemy_defeated(currency_enemy)
		currency_enemy.free()
		_expect(arena.survivor_currency == 1 and game.session.currency == 1 and "0001" in arena.hud.currency_label.text, "enemy drops must update the HUD and persistent survivor currency")
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		arena.player._input(click)
		_expect(arena.player._dodge_left > 0.0, "left click must still trigger dash")
		await create_timer(1.2).timeout
		_expect(arena.get_tree().get_nodes_in_group(&"battle_enemy").size() > 0, "survival combat must materialize warned enemies")
		var spawned_bosses := ContentFactory.bosses()
		_expect(spawned_bosses.size() == 1 and spawned_bosses[0].base_max_hp == 420.0, "survival boss must be a registered codex enemy with live combat stats")
		arena._finish(false)
	await process_frame
	await process_frame
	_expect(game.flow.state == RunFlowController.State.RESULT, "survivor death must enter the survival result screen")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("INTEGRATION PASS: survival main flow and all archives")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("INTEGRATION FAIL: %d failures" % failures.size())
		quit(1)