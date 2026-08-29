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
	var main_menu_buttons: Array[Node] = game.root_control.find_children("*", "Button", true, false)
	var has_codex_button := false
	for button_node in main_menu_buttons:
		var menu_button := button_node as Button
		if menu_button != null and menu_button.text.begins_with("카드 도감"):
			has_codex_button = true
			break
	_expect(has_codex_button, "main menu must expose a dedicated card archive button")
	game._open_card_codex()
	await process_frame
	_expect(game.root_control.find_children("CardCodexCard_*", "Button", true, false).size() == 48, "card archive must display every registered card")
	var codex_scroll := game.root_control.find_child("CardCodexScroll", true, false) as ScrollContainer
	_expect(codex_scroll != null and codex_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "card archive collection must be vertically scrollable")
	_expect(game.root_control.find_child("CardCodexDetail", true, false) != null, "card archive must display a selected-card detail panel")
	game._set_codex_family_filter(1)
	await process_frame
	_expect(game.root_control.find_children("CardCodexCard_*", "Button", true, false).size() == 8, "each card-family filter must expose its eight-card set")
	var expected_common_swords := 0
	for card in game.all_cards:
		if card.family_id == &"sword" and card.rarity == CardDef.Rarity.COMMON:
			expected_common_swords += 1
	game._set_codex_rarity_filter(1)
	await process_frame
	_expect(game.root_control.find_children("CardCodexCard_*", "Button", true, false).size() == expected_common_swords, "rarity filter must combine with the selected family")
	game._show_main_menu()
	await process_frame
	game._begin_new_run()
	game._select_map(game.all_maps[0], false)
	game._select_character(game.all_characters[0])
	var family: StringName = game.selected_character.allowed_starting_families[0]
	game._start_run(family)
	await process_frame
	_expect(game.session != null, "UI flow must create a run session")
	_expect(ComboValidator.validate(game.deck, game.cycle)["valid"], "UI flow must create a valid automatic cycle")
	_expect(game.flow.state == RunFlowController.State.ENCOUNTER, "first family selection must skip map/deck screens and enter combat immediately")
	_expect(game.map_controller.run_map.get_node(game.map_controller.current_node_id).type == MapNode.Type.COMBAT, "automatic first node must be a combat node")
	_expect(game.session.visited_node_ids.size() == 1, "automatic first combat must be recorded as visited")
	var arena: BattleArena
	for child in game.root_control.get_children():
		if child is BattleArena:
			arena = child
	_expect(arena != null, "combat screen must instantiate BattleArena")
	if arena:
		_expect(arena.camera != null and arena.camera.enabled, "battle must create an enabled player-follow camera")
		_expect(arena.camera.get_parent() == arena.player, "battle camera must be parented to the player")
		_expect(arena.player.arena_rect.size.x > 1280.0 and arena.player.arena_rect.size.y > 720.0, "player must move inside a world larger than the viewport")
		_expect(arena.spawn_timer >= 4.0, "regular enemy wave must have an initial grace period")
		_expect(arena.get_tree().get_nodes_in_group(&"spawn_warning").size() == 2, "initial enemies must show spawn warnings before materializing")
		_expect(arena.get_tree().get_nodes_in_group(&"battle_enemy").is_empty(), "enemy must not exist during its one-second warning")
		_expect(arena.hud != null, "combat must instantiate the dedicated BattleHud canvas layer")
		_expect(arena.hud.root_control.mouse_filter == Control.MOUSE_FILTER_IGNORE, "HUD must never consume combat mouse input")
		_expect(arena.hud.relic_rail.displayed_slot_count == 8, "relic rail must expose eight empty placeholder slots")
		_expect(not arena.hud.consumable_panel.visible, "consumable HUD must be hidden while its feature flag is disabled")
		_expect(not arena.player.consumables_enabled, "consumable input feature flag must default to disabled")
		_expect(arena.hud.combo_rail.active_card_indices.size() == game.cycle.combos.size(), "combo rail must expose every configured parallel lane")
		_expect(arena.hud.combo_rail.position.x == 100 and arena.hud.combo_rail.size.x == 1080, "combo rail must expand into the hidden consumable space")
		var wheel := InputEventMouseButton.new()
		wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
		wheel.pressed = true
		arena.player._input(wheel)
		await process_frame
		_expect(arena.player.selected_consumable == 0, "mouse wheel must do nothing while consumables are disabled")
		var defense_before := int(arena.player.consumables[1]["count"])
		var right_click := InputEventMouseButton.new()
		right_click.button_index = MOUSE_BUTTON_RIGHT
		right_click.pressed = true
		arena.player._input(right_click)
		await process_frame
		_expect(int(arena.player.consumables[1]["count"]) == defense_before, "right click must do nothing while consumables are disabled")
		arena.hud.activate_card(0, 0)
		_expect(arena.hud.combo_rail.active_card_indices[0] == 0, "executed card must visibly activate in its own combo lane")
		_expect(arena.hud.cooldown_widget.snapshots.size() == game.cycle.combos.size(), "cooldown data source must track every running lane")
		_expect(not arena.hud.cooldown_widget.visible, "legacy detached cooldown panel must stay hidden")
		_expect(arena.hud.combo_rail.snapshots_by_lane.size() == game.cycle.combos.size(), "each visible combo slot must receive its own outline timer")
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		arena.player._input(click)
		_expect(arena.player._dodge_left > 0.0, "left mouse click must start the player dash even under Control HUD")
		await create_timer(1.2).timeout
		_expect(arena.get_tree().get_nodes_in_group(&"battle_enemy").size() > 0, "pattern combat must keep active enemies during simulation")
		_expect(arena.get_tree().get_nodes_in_group(&"spawn_warning").is_empty(), "spawn warning must end after one second")
		arena._finish(true)
	await process_frame
	await process_frame
	_expect(game.flow.state == RunFlowController.State.REWARD, "successful combat must enter reward state")
	game._finish_node()
	await process_frame
	_expect(game.flow.state == RunFlowController.State.RUN_MAP, "reward completion must return to run map")
	_expect(game.map_controller.available_nodes().size() <= 3, "post-combat map must expose at most three nodes")
	var next_node: MapNode = game.map_controller.available_nodes()[0]
	game._select_node(next_node)
	await process_frame
	_expect(game.flow.state == RunFlowController.State.DECK_EDIT, "later node selection must still open combo editor before entry")
	_expect(game.pending_node == next_node, "combo editor must retain the selected later destination")
	_expect(game.root_control.find_children("*", "ComboDragCard", true, false).size() == game.deck.cards.size(), "every deck card in the editor must be draggable")
	_expect(game.root_control.find_children("*", "ComboDropZone", true, false).size() == game.cycle.combos.size() + 1, "editor must expose one drop zone per dynamic combo plus unassigned")
	var editor_scroll := game.root_control.find_child("ComboEditorScroll", true, false) as ScrollContainer
	_expect(editor_scroll != null and editor_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO and editor_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "combo editor must provide horizontal and vertical scrolling")
	var combo_count_before: int = game.cycle.combos.size()
	game._add_combo_slot()
	await process_frame
	_expect(game.cycle.combos.size() == combo_count_before + 1, "combo editor must allow adding a free combo slot")
	_expect(game.root_control.find_children("*", "ComboDropZone", true, false).size() == game.cycle.combos.size() + 1, "adding a combo must create another draggable drop zone")
	_expect(not bool(ComboValidator.validate(game.deck, game.cycle)["valid"]), "a newly added empty combo must remain visible and block confirmation")
	var card_to_preserve: StringName = game.cycle.combos[0].card_instance_ids[0]
	game._drop_combo_card(card_to_preserve, game.cycle.combos.size() - 1, 0)
	await process_frame
	game._remove_combo_slot(game.cycle.combos.size() - 1)
	await process_frame
	_expect(game.cycle.combos.size() == combo_count_before, "combo editor must allow removing a combo slot")
	var preserved_count := 0
	for combo in game.cycle.combos:
		preserved_count += combo.card_instance_ids.count(card_to_preserve)
	_expect(preserved_count == 1 and bool(ComboValidator.validate(game.deck, game.cycle)["valid"]), "removing a populated combo must preserve and redistribute every card exactly once")
	var editor_cards: Array[Node] = game.root_control.find_children("*", "ComboDragCard", true, false)
	var first_editor_card: ComboDragCard = null
	if not editor_cards.is_empty():
		first_editor_card = editor_cards[0] as ComboDragCard
	_expect(first_editor_card != null and first_editor_card.custom_minimum_size.y >= 76.0, "editor cards must use a readable multi-line vertical tile")
	var dragged_card_id: StringName = game.cycle.combos[0].card_instance_ids[0]
	game._drop_combo_card(dragged_card_id, 1, 0)
	await process_frame
	_expect(game.cycle.combos[1].card_instance_ids[0] == dragged_card_id, "dropping a card onto another combo must move it to the requested insertion point")
	_expect(dragged_card_id not in game.cycle.combos[0].card_instance_ids, "drag move must remove the card from its original combo")
	game._drop_combo_card(dragged_card_id, 1, game.cycle.combos[1].card_instance_ids.size())
	await process_frame
	_expect(game.cycle.combos[1].card_instance_ids[-1] == dragged_card_id, "dropping inside the same combo must reorder its activation sequence")
	game._drop_combo_card(dragged_card_id, 0, 0)
	await process_frame
	game.flow.state = RunFlowController.State.ENCOUNTER
	game._on_battle_completed(true, {"node_type": MapNode.Type.BOSS, "kills": 1})
	await process_frame
	_expect(game.flow.state == RunFlowController.State.RESULT, "standard boss clear must enter result state")
	_expect(game.unlocks.is_unlocked("endless_maps", game.selected_map.id), "boss clear must unlock endless mode")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("INTEGRATION PASS: complete UI run flow")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("INTEGRATION FAIL: %d failures" % failures.size())
		quit(1)
