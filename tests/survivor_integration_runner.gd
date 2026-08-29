extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred(&"_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	var packed := load("res://scenes/Main.tscn") as PackedScene
	_expect(packed != null, "Main scene must load for infinite survival")
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	game._begin_survivor()
	await process_frame
	game._select_character(game.all_characters[0])
	game._confirm_character_selection()
	await process_frame
	var family: StringName = game.selected_character.allowed_starting_families[0]
	game._select_family(family)
	game._confirm_family_selection()
	await process_frame
	game._select_map(game.all_maps[0])
	game._confirm_map_selection()
	await process_frame
	var arena: BattleArena = game.survivor_arena
	_expect(game.session.mode == RunSession.Mode.SURVIVOR, "primary menu path must create a survivor session")
	_expect(game.flow.state == RunFlowController.State.ENCOUNTER, "survival path must skip node generation and enter endless combat")
	_expect(game.run_map == null, "survival path must not generate or consume a node map")
	_expect(arena != null and arena.survivor_mode, "survival path must instantiate a survivor BattleArena")
	if arena:
		_expect(game.survivor_level_overlay == null, "level-up controls must remain hidden during ordinary combat")
		_expect(arena.hud.xp_bar.visible and arena.hud.xp_label.visible, "survivor HUD must display level and XP progress")
		_expect(game.cycle.combos.size() == game.selected_character.combo_slot_count(game.session.combo_slot_modifier), "character data must determine the live combo slot count")
		var live_deck_before_level := arena.deck
		var fixed_lane_count: int = game.cycle.combos.size()
		_expect(arena.duration > 0.0 and not arena.ended, "survivor combat must start without a timed completion")
		var fake_enemy := BattleEnemy.new()
		fake_enemy.is_boss = false
		for _index in 6:
			arena._on_enemy_defeated(fake_enemy)
		fake_enemy.free()
		await process_frame
		_expect(paused, "reaching the XP threshold must pause the entire combat tree")
		_expect(arena.survivor_progression.level == 2, "six normal defeats must reach survivor level two")
		_expect(is_instance_valid(game.survivor_level_overlay), "level up must display the reward overlay")
		_expect(game.deck != live_deck_before_level and arena.deck == live_deck_before_level, "reward editing must use a staged deck without mutating active combat")
		_expect(game.survivor_level_overlay.find_children("SurvivorCardOffer_*", "Button", true, false).size() == 3, "reward screen must show three candidates while allowing only one acquisition")
		_expect(game.survivor_level_overlay.find_child("SurvivorRerollButton", true, false) != null, "reward screen must provide card reroll")
		_expect(game.survivor_level_overlay.find_children("*", "ComboDropZone", true, false).is_empty(), "deck refinement controls must not share the reward screen")
		_expect(game.survivor_level_overlay.find_children("*", "ComboDragCard", true, false).is_empty(), "reward screen must contain reward information only")
		var previous_offer_ids: Array[StringName] = []
		for offer in game.survivor_card_offers:
			previous_offer_ids.append(offer.id)
		game._survivor_reroll_cards(arena, arena.survivor_progression.level, arena.survivor_progression.xp, arena.survivor_progression.next_xp)
		await process_frame
		var reroll_changed_every_card := true
		for offer in game.survivor_card_offers:
			if previous_offer_ids.has(offer.id):
				reroll_changed_every_card = false
		_expect(game.survivor_card_rerolls_left == 0 and reroll_changed_every_card, "one reroll must replace the complete card offer set")
		var deck_size_before_action: int = game.deck.cards.size()
		var chosen_offer: CardDef = game.survivor_card_offers[0]
		game._survivor_take_card(arena, chosen_offer, arena.survivor_progression.level, arena.survivor_progression.xp, arena.survivor_progression.next_xp)
		await process_frame
		_expect(game.survivor_reward_claimed and game.survivor_level_action == "acquire", "taking one card must consume the level action")
		_expect(game.deck.cards.size() == deck_size_before_action + 1, "exactly one offered card must be added")
		_expect(game.cycle.combos.size() == fixed_lane_count, "reward actions must not add or remove character-defined combo slots")
		_expect(game.survivor_level_overlay.find_children("*", "ComboDropZone", true, false).size() == fixed_lane_count, "refinement screen must expose only the fixed combo drop zones")
		_expect(game.survivor_level_overlay.find_children("*", "ComboDragCard", true, false).size() == game.deck.cards.size(), "all owned cards must become draggable on the separate refinement screen")
		_expect(game.survivor_level_overlay.find_child("SurvivorDeleteChoiceScroll", true, false) == null, "card deletion choices must disappear after an acquisition")
		var size_after_acquire: int = game.deck.cards.size()
		game.survivor_reward_view = "delete"
		game._survivor_delete_card(arena, game.deck.cards[-1].instance_id, arena.survivor_progression.level, arena.survivor_progression.xp, arena.survivor_progression.next_xp)
		game._survivor_take_card(arena, game.survivor_card_offers[1], arena.survivor_progression.level, arena.survivor_progression.xp, arena.survivor_progression.next_xp)
		_expect(game.deck.cards.size() == size_after_acquire, "acquisition must lock both further acquisition and deletion for this level")
		_expect(arena.deck == live_deck_before_level, "staged reward and refinement must not replace active cards while paused")
		var survivor_scroll := game.survivor_level_overlay.find_child("SurvivorComboScroll", true, false) as ScrollContainer
		_expect(survivor_scroll != null and survivor_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO and survivor_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "separate refinement board must scroll in both directions")
		_expect(bool(ComboValidator.validate(game.deck, game.cycle)["valid"]), "card acquisition must preserve a valid fixed-lane cycle")
		game._resume_survivor(arena)
		_expect(arena.runner.has_pending_configuration(), "resuming after refinement must queue the deck until current combo cycles finish")
		_expect(arena.deck == live_deck_before_level, "resuming must preserve the active deck until a cycle boundary")
		await process_frame
		_expect(not paused, "confirming refinement must resume combat")
		_expect(not arena.survivor_level_up_pending, "resuming must clear the pending level-up gate")
		var second_level_enemy := BattleEnemy.new()
		for _index in 9:
			arena._on_enemy_defeated(second_level_enemy)
		second_level_enemy.free()
		await process_frame
		_expect(paused and game.survivor_level_stage == game.SurvivorLevelStage.REWARD, "next level must reopen only the reward action screen")
		game.survivor_reward_view = "delete"
		game._show_survivor_level_overlay(arena, arena.survivor_progression.level, arena.survivor_progression.xp, arena.survivor_progression.next_xp)
		await process_frame
		_expect(game.survivor_level_overlay.find_child("SurvivorDeleteChoiceScroll", true, false) != null, "delete action must have its own uncluttered card list")
		var size_before_delete: int = game.deck.cards.size()
		var delete_id: StringName = game.deck.cards[-1].instance_id
		game._survivor_delete_card(arena, delete_id, arena.survivor_progression.level, arena.survivor_progression.xp, arena.survivor_progression.next_xp)
		await process_frame
		_expect(game.deck.cards.size() == size_before_delete - 1 and game.survivor_level_action == "delete", "delete action must remove exactly one card")
		game._survivor_take_card(arena, game.survivor_card_offers[0], arena.survivor_progression.level, arena.survivor_progression.xp, arena.survivor_progression.next_xp)
		_expect(game.deck.cards.size() == size_before_delete - 1, "deleting a card must lock acquisition for that level")
		_expect(game.survivor_level_overlay.find_children("*", "ComboDropZone", true, false).size() == fixed_lane_count, "delete action must proceed to the separate fixed-slot refinement screen")
		_expect(bool(ComboValidator.validate(game.deck, game.cycle)["valid"]), "single deletion must preserve a refinable valid cycle")
		game._resume_survivor(arena)
		await process_frame
		_expect(not paused, "second level deletion refinement must resume combat")
		arena.elapsed = arena.duration + 100.0
		arena._process(0.01)
		_expect(not arena.ended, "infinite survival combat must not end at a wave timer")
		arena._finish(false)
	await process_frame
	await process_frame
	_expect(game.flow.state == RunFlowController.State.RESULT, "survivor death must enter its result screen")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("SURVIVOR INTEGRATION PASS: infinite survival level-up flow")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("SURVIVOR INTEGRATION FAIL: %d failures" % failures.size())
		quit(1)
