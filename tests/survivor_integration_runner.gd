extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred(&"_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	var packed := load("res://scenes/Main.tscn") as PackedScene
	_expect(packed != null, "Main scene must load for survivor A/B test")
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	game._begin_survivor_test()
	game._select_map(game.all_maps[0], false)
	game._select_character(game.all_characters[0])
	var family: StringName = game.selected_character.allowed_starting_families[0]
	game._start_run(family)
	await process_frame
	var arena: BattleArena = game.survivor_arena
	_expect(game.session.mode == RunSession.Mode.SURVIVOR_AB, "B menu path must create a survivor A/B session")
	_expect(game.flow.state == RunFlowController.State.ENCOUNTER, "B path must skip node generation and enter endless combat")
	_expect(game.run_map == null, "B path must not generate or consume the standard node map")
	_expect(arena != null and arena.survivor_mode, "B path must instantiate a survivor BattleArena")
	if arena:
		_expect(arena.hud.xp_bar.visible and arena.hud.xp_label.visible, "survivor HUD must display level and XP progress")
		_expect(arena.duration > 0.0 and not arena.ended, "survivor combat must start without a timed completion")
		var fake_enemy := BattleEnemy.new()
		fake_enemy.is_boss = false
		for _index in 6:
			arena._on_enemy_defeated(fake_enemy)
		fake_enemy.free()
		await process_frame
		_expect(paused, "reaching the XP threshold must pause the entire combat tree")
		_expect(arena.survivor_progression.level == 2, "six normal defeats must reach survivor level two")
		_expect(is_instance_valid(game.survivor_level_overlay), "level up must display the reward and deck-management overlay")
		_expect(game.survivor_level_overlay.find_children("*", "ComboDropZone", true, false).size() == game.cycle.combos.size() + 1, "level overlay must expose one dynamic combo drop zone plus the delete zone")
		_expect(game.survivor_level_overlay.find_children("*", "ComboDragCard", true, false).size() == game.deck.cards.size(), "every owned card must be draggable while combat is paused")
		var survivor_scroll := game.survivor_level_overlay.find_child("SurvivorComboScroll", true, false) as ScrollContainer
		_expect(survivor_scroll != null and survivor_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO and survivor_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "level overlay combo board must scroll in both directions")
		var lane_count_before: int = game.cycle.combos.size()
		game._survivor_add_combo(arena, arena.survivor_progression.level, arena.survivor_progression.xp, arena.survivor_progression.next_xp)
		await process_frame
		_expect(game.cycle.combos.size() == lane_count_before + 1, "level overlay must add combo slots without a fixed A/B/C limit")
		_expect(not bool(ComboValidator.validate(game.deck, game.cycle)["valid"]), "empty added survivor combo must stay visible until filled or removed")
		game._survivor_remove_combo(arena, game.cycle.combos.size() - 1, arena.survivor_progression.level, arena.survivor_progression.xp, arena.survivor_progression.next_xp)
		await process_frame
		_expect(game.cycle.combos.size() == lane_count_before, "level overlay must remove a selected combo slot")
		var relic: Dictionary = game._survivor_next_relic(arena.survivor_progression.level)
		game._survivor_take_relic(arena, relic, arena.survivor_progression.level, arena.survivor_progression.xp, arena.survivor_progression.next_xp)
		await process_frame
		_expect(game.survivor_reward_claimed, "choosing a relic must satisfy the level reward")
		_expect(arena.survivor_relics.size() == 1 and game.session.relic_ids.size() == 1, "chosen relic must apply to combat and persist in the run session")
		_expect(arena.hud.relic_rail.relics.size() == 1, "chosen relic must appear in the combat HUD rail")
		var deck_before: int = game.deck.cards.size()
		var removable_id: StringName = game.deck.cards[-1].instance_id
		game._survivor_delete_card(arena, removable_id, arena.survivor_progression.level, arena.survivor_progression.xp, arena.survivor_progression.next_xp)
		await process_frame
		_expect(game.deck.cards.size() == deck_before - 1, "level overlay must allow deleting a removable card")
		_expect(bool(ComboValidator.validate(game.deck, game.cycle)["valid"]), "deck deletion must keep the live combo cycle valid")
		game._resume_survivor(arena)
		await process_frame
		_expect(not paused, "confirming the level build must resume combat")
		_expect(not arena.survivor_level_up_pending, "resuming must clear the pending level-up gate")
		arena.elapsed = arena.duration + 100.0
		arena._process(0.01)
		_expect(not arena.ended, "survivor B combat must not end at the standard wave timer")
		arena._finish(false)
	await process_frame
	await process_frame
	_expect(game.flow.state == RunFlowController.State.RESULT, "survivor death must enter its comparison result screen")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("SURVIVOR INTEGRATION PASS: A/B endless level-up flow")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("SURVIVOR INTEGRATION FAIL: %d failures" % failures.size())
		quit(1)
