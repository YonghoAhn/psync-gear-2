extends SceneTree

var suite: TestSuite


func _init() -> void:
	call_deferred(&"_run_all")


func _run_all() -> void:
	suite = TestSuite.new()
	_run_rng_tests()
	_run_registry_tests()
	_run_session_tests()
	_run_flow_tests()
	_run_combo_tests()
	_run_cycle_tests()
	_run_synergy_tests()
	_run_reward_tests()
	_run_combat_stats_tests()
	_run_damage_tests()
	_run_status_rule_tests()
	_run_consumable_tests()
	_run_character_tests()
	_run_unlock_tests()
	_run_enemy_role_tests()
	_run_boss_pattern_tests()
	_run_map_tests()
	_run_encounter_tests()
	_run_node_service_tests()
	_run_content_tests()
	_run_survivor_tests()
	_run_persistence_tests()
	_run_telemetry_tests()
	_run_generation_stress_tests()
	_run_script_parse_tests(&"res://")
	if suite.is_success():
		print("TEST PASS: %d assertions" % suite.assertions)
		suite = null
		quit(0)
	else:
		for failure in suite.failures:
			push_error(failure)
		print("TEST FAIL: %d failures / %d assertions" % [suite.failures.size(), suite.assertions])
		suite = null
		quit(1)


func _run_rng_tests() -> void:
	var left := RunRng.new(20260808)
	var right := RunRng.new(20260808)
	for index in 10:
		suite.expect_eq(left.randi_range(&"map", 0, 9999), right.randi_range(&"map", 0, 9999), "named stream must be deterministic at %d" % index)

	var isolated := RunRng.new(20260808)
	isolated.randi_range(&"reward", 0, 9999)
	suite.expect_eq(RunRng.new(20260808).randi_range(&"map", 0, 9999), isolated.randi_range(&"map", 0, 9999), "streams must not perturb each other")


func _run_registry_tests() -> void:
	var registry := ContentRegistry.new()
	suite.expect_true(registry.register(&"card", &"fireball", {"name": "Fireball"}), "first id registration should succeed")
	suite.expect_true(not registry.register(&"card", &"fireball", {}), "duplicate id must fail")
	suite.expect_true(not registry.validate(), "registry with duplicate errors must be invalid")


func _run_session_tests() -> void:
	var original := RunSession.create(77, &"foundry", &"vanguard", &"sword")
	original.add_currency(120)
	original.combo_slot_modifier = 1
	suite.expect_true(original.spend_currency(35), "affordable purchase should succeed")
	suite.expect_true(not original.spend_currency(999), "unaffordable purchase should fail")
	original.visit_node(&"node_1")
	var restored := RunSession.from_dict(original.to_dict())
	suite.expect_eq(restored.currency, 85, "currency must survive serialization")
	suite.expect_eq(restored.map_id, &"foundry", "map id must survive serialization")
	suite.expect_eq(restored.visited_node_ids, [&"node_1"], "visited nodes must survive serialization")
	suite.expect_eq(restored.combo_slot_modifier, 1, "combo slot relic modifier must survive serialization")


func _run_flow_tests() -> void:
	var flow := RunFlowController.new()
	suite.expect_true(flow.transition(RunFlowController.State.MAIN_MENU), "boot should enter main menu")
	suite.expect_true(not flow.transition(RunFlowController.State.ENCOUNTER), "invalid state jump must be rejected")
	suite.expect_true(flow.transition(RunFlowController.State.CHARACTER_SELECT), "main menu should enter character select")
	suite.expect_true(flow.transition(RunFlowController.State.STARTING_FAMILY_SELECT), "character select should enter family select")
	suite.expect_true(flow.transition(RunFlowController.State.MAP_SELECT), "family select should enter map select")
	suite.expect_true(flow.transition(RunFlowController.State.RUN_MAP), "map select should enter the survival run")


func _card(id: StringName, family: StringName, delay: float = 0.1, neutral: bool = false) -> CardInstance:
	var definition := CardDef.new()
	definition.id = id
	definition.display_name = String(id)
	definition.family_id = family
	definition.execution_interval = delay
	definition.is_neutral = neutral
	definition.role = CardDef.Role.UTILITY if neutral else CardDef.Role.ATTACK
	return CardInstance.create(definition, &"test", StringName("instance_%s" % id))


func _deck_with(cards: Array[CardInstance]) -> DeckState:
	var deck := DeckState.new()
	for card in cards:
		deck.add_card(card)
	return deck


func _run_combo_tests() -> void:
	var a := _card(&"a", &"fire", 2)
	var b := _card(&"b", &"fire", 2)
	var deck := _deck_with([a, b])
	var combo := ComboState.create(&"combo_a", 1)
	combo.card_instance_ids.assign([a.instance_id, b.instance_id])
	var cycle := CycleState.new()
	cycle.combos.append(combo)
	suite.expect_true(ComboValidator.validate(deck, cycle)["valid"], "legacy cost limit must not reject a complete assignment")
	combo.card_instance_ids.append(a.instance_id)
	suite.expect_true(not ComboValidator.validate(deck, cycle)["valid"], "duplicate card assignment must fail")

	var arena := BattleArena.new()
	suite.expect_true(is_equal_approx(arena._advance_combo_family_chain(&"combo_a", &"fire"), 1.0), "first card in a family chain must deal base damage")
	suite.expect_true(is_equal_approx(arena._advance_combo_family_chain(&"combo_a", &"fire"), 1.05), "second consecutive same-family card must gain five percentage points")
	suite.expect_true(is_equal_approx(arena._advance_combo_family_chain(&"combo_a", &"fire"), 1.10), "third consecutive same-family card must gain ten percentage points")
	suite.expect_true(is_equal_approx(arena._advance_combo_family_chain(&"combo_b", &"fire"), 1.0), "family chains must be tracked independently per combo lane")
	suite.expect_true(is_equal_approx(arena._advance_combo_family_chain(&"combo_a", &"water"), 1.0), "changing card family must reset the damage multiplier to one")
	suite.expect_true(is_equal_approx(arena._advance_combo_family_chain(&"combo_a", &"water"), 1.05), "a new family must start its own consecutive chain")
	arena.free()


func _run_cycle_tests() -> void:
	var a := _card(&"cycle_a", &"fire")
	var b := _card(&"cycle_b", &"fire")
	b.card_def.execution_interval = 0.25
	var deck := _deck_with([a, b])
	var first := ComboState.create(&"first")
	first.card_instance_ids.append(a.instance_id)
	var second := ComboState.create(&"second")
	second.card_instance_ids.append(b.instance_id)
	var cycle := CycleState.new()
	cycle.combos.assign([first, second])
	var executed: Array[StringName] = []
	var runner := CycleRunner.new()
	suite.expect_true(runner.configure(deck, cycle, func(card): executed.append(card.card_def.id)), "valid cycle should configure")
	runner.start()
	runner.tick(0.0)
	suite.expect_eq(executed, [&"cycle_a", &"cycle_b"], "all combo lanes must fire together on the first frame")
	var lane_snapshots := runner.cooldown_snapshots()
	suite.expect_eq(lane_snapshots.size(), 2, "parallel runner must expose one cooldown timeline per lane")
	suite.expect_true(absf(ComboCardRail.card_position_ratio(1, 4) - 0.5) < 0.001, "second card in a four-card combo must fill half the outline")
	suite.expect_eq(ComboCardRail.card_position_ratio(3, 4), 1.0, "last card must complete the combo outline")
	var rail := ComboCardRail.new()
	rail.setup(deck, cycle)
	suite.expect_eq(rail.active_card_indices.size(), 2, "combo HUD lane count must follow the configured dynamic cycle")
	suite.expect_eq(ComboCardRail.combo_label(26), "AA", "dynamic combo labels must continue past Z")
	var many_cycle := CycleState.new()
	for lane_index in range(9):
		many_cycle.combos.append(ComboState.create(StringName("lane_%d" % lane_index)))
	rail.setup(deck, many_cycle)
	suite.expect_eq(rail.active_card_indices.size(), 9, "combo HUD must not truncate dynamically added lanes")
	suite.expect_eq(rail._page_count(), 3, "combat combo HUD must paginate lanes in groups of four")
	rail.free()
	runner.tick(0.11)
	suite.expect_eq(executed, [&"cycle_a", &"cycle_b", &"cycle_a"], "fast lane must repeat without waiting for a slower lane")
	suite.expect_true(float(runner.cooldown_snapshots()[1]["remaining"]) > 0.1, "slower lane must retain its own independent cooldown")
	var heavy := _card(&"cycle_heavy", &"fire")
	heavy.card_def.execution_interval = 5.0
	heavy.card_def.effect_delay = 1.0
	var followup := _card(&"cycle_followup", &"fire")
	var heavy_deck := _deck_with([heavy, followup])
	var heavy_combo := ComboState.create(&"heavy_combo")
	heavy_combo.card_instance_ids.assign([heavy.instance_id, followup.instance_id])
	var heavy_cycle := CycleState.new()
	heavy_cycle.combos.append(heavy_combo)
	var heavy_executed: Array[StringName] = []
	var heavy_runner := CycleRunner.new()
	suite.expect_true(heavy_runner.configure(heavy_deck, heavy_cycle, func(card): heavy_executed.append(card.card_def.id)), "heavy cycle should configure")
	heavy_runner.start()
	heavy_runner.tick(0.0)
	suite.expect_eq(heavy_executed, [&"cycle_heavy"], "heavy card must dispatch immediately")
	var cooldown := heavy_runner.cooldown_snapshot()
	suite.expect_eq(cooldown["card"], heavy, "cooldown snapshot must identify the active card")
	suite.expect_true(absf(float(cooldown["remaining"]) - 5.0) < 0.01, "cooldown snapshot must expose visible remaining seconds")
	suite.expect_true(absf(float(cooldown["ratio"]) - 1.0) < 0.01, "cooldown snapshot must begin full")
	heavy_runner.tick(1.0)
	suite.expect_eq(heavy_executed, [&"cycle_heavy"], "heavy card cooldown must continue without dispatching followup early")
	heavy_runner.tick(4.01)
	suite.expect_eq(heavy_executed, [&"cycle_heavy", &"cycle_followup"], "followup must dispatch when heavy cooldown expires")

	var old_a := _card(&"old_a", &"sword", 0.2)
	var old_b := _card(&"old_b", &"sword", 0.3)
	var old_c := _card(&"old_c", &"water", 0.5)
	var old_deck := _deck_with([old_a, old_b, old_c])
	var old_lane_a := ComboState.create(&"old_lane_a")
	old_lane_a.card_instance_ids.assign([old_a.instance_id, old_b.instance_id])
	var old_lane_b := ComboState.create(&"old_lane_b")
	old_lane_b.card_instance_ids.append(old_c.instance_id)
	var old_cycle := CycleState.new()
	old_cycle.combos.assign([old_lane_a, old_lane_b])
	var replacement := _card(&"replacement", &"fire", 0.1)
	var replacement_deck := _deck_with([replacement])
	var replacement_lane := ComboState.create(&"replacement_lane")
	replacement_lane.card_instance_ids.append(replacement.instance_id)
	var replacement_cycle := CycleState.new()
	replacement_cycle.combos.append(replacement_lane)
	var deferred_executed: Array[StringName] = []
	var deferred_runner := CycleRunner.new()
	suite.expect_true(deferred_runner.configure(old_deck, old_cycle, func(card): deferred_executed.append(card.card_def.id)), "deferred cycle should configure")
	deferred_runner.start()
	deferred_runner.tick(0.0)
	suite.expect_eq(deferred_executed, [&"old_a", &"old_c"], "old lanes must already be executing before a level-up edit")
	suite.expect_true(deferred_runner.queue_configuration(replacement_deck, replacement_cycle), "valid edited deck must queue")
	deferred_runner.tick(0.2)
	suite.expect_eq(deferred_executed, [&"old_a", &"old_c", &"old_b"], "queued edits must not interrupt the current lane cycle")
	deferred_runner.tick(0.31)
	suite.expect_true(not deferred_runner.has_pending_configuration(), "edited deck must apply only after every old lane reaches its cycle boundary")
	suite.expect_eq(deferred_executed, [&"old_a", &"old_c", &"old_b"], "replacement first card must wait until the tick after configuration is applied")
	deferred_runner.tick(0.0)
	suite.expect_eq(deferred_executed, [&"old_a", &"old_c", &"old_b", &"replacement"], "edited deck must begin from its first card on the following execution")


func _run_synergy_tests() -> void:
	var fire_a := _card(&"fire_a", &"fire")
	var neutral := _card(&"neutral", &"neutral", 1, true)
	var fire_b := _card(&"fire_b", &"fire")
	var deck := _deck_with([fire_a, neutral, fire_b])
	var combo := ComboState.create(&"synergy")
	combo.card_instance_ids.assign([fire_a.instance_id, neutral.instance_id, fire_b.instance_id])
	var synergy := SynergyResolver.combo_synergy(combo, deck)
	suite.expect_eq(synergy["family_id"], &"fire", "neutral utility must not break family synergy")
	suite.expect_eq(synergy["tier"], 1, "two same-family cards should grant tier one")
	var water := _card(&"water", &"water")
	deck.add_card(water)
	combo.card_instance_ids.append(water.instance_id)
	suite.expect_eq(SynergyResolver.combo_synergy(combo, deck)["tier"], 0, "mixed families must disable combo synergy")


func _run_reward_tests() -> void:
	var fire_owned := _card(&"owned_fire", &"fire")
	var deck := _deck_with([fire_owned])
	var pool: Array[CardDef] = []
	for id in [&"offer_fire_1", &"offer_fire_2", &"offer_water", &"offer_sword"]:
		var definition := CardDef.new()
		definition.id = id
		definition.family_id = &"fire" if "fire" in String(id) else &"other"
		pool.append(definition)
	var offer := RewardOfferService.create_offer(pool, deck, RunRng.new(55), 3)
	suite.expect_eq(offer.size(), 3, "reward service should produce three distinct cards")
	suite.expect_true(offer[0] != offer[1], "reward cards must be distinct")


func _run_combat_stats_tests() -> void:
	var stats := CombatStatsComponent.new()
	stats.base_magic_power = 20.0
	stats.add_modifier(&"card", &"magic_power", "flat", 10.0)
	stats.add_modifier(&"set", &"magic_power", "percent", 50.0)
	suite.expect_eq(stats.magic_power, 45.0, "flat then percent stat modifiers must compose")
	stats.remove_modifiers_by_source(&"card")
	suite.expect_eq(stats.magic_power, 30.0, "removing a source must recalculate stat")
	stats.free()


func _run_damage_tests() -> void:
	var attacker := CombatStatsComponent.new()
	attacker.base_magic_power = 20.0
	var defender := CombatStatsComponent.new()
	defender.base_defense = 100.0
	defender.base_resist_physical = 0.2
	var physical := DamageContext.create(100.0, 0.0, DamageContext.Type.PHYSICAL)
	physical.attacker_stats = attacker
	suite.expect_eq(DamagePipeline.calculate(physical, defender), 40.0, "defense and resistance formula must match design")
	var pure := DamageContext.create(100.0, 0.0, DamageContext.Type.PURE)
	suite.expect_eq(DamagePipeline.calculate(pure, defender), 100.0, "pure damage must ignore defense and resistance")
	var scaled := DamageContext.create(10.0, 1.5, DamageContext.Type.MAGIC)
	scaled.attacker_stats = attacker
	scaled.critical = true
	scaled.critical_multiplier = 2.0
	suite.expect_eq(DamagePipeline.calculate(scaled, null), 80.0, "base plus coefficient then critical must follow formula order")
	attacker.free()
	defender.free()


func _run_status_rule_tests() -> void:
	var definition := StatusDef.new()
	definition.id = &"burning"
	definition.base_duration = 10.0
	definition.max_stacks = 10
	definition.immunity_tag = &"immune_fire"
	var resisted := StatusResolver.resolve(definition, 4, [], 0.5)
	suite.expect_eq(resisted["stacks"], 2, "tenacity must reduce status stacks")
	suite.expect_eq(resisted["duration"], 5.0, "tenacity must reduce duration")
	suite.expect_true(not StatusResolver.resolve(definition, 4, [&"immune_fire"], 0.0)["applied"], "immunity tag must reject status")


func _run_consumable_tests() -> void:
	var controller := ConsumableController.new()
	controller.add(&"potion", 2)
	controller.add(&"bomb", 1)
	suite.expect_true(controller.use_selected(), "selected consumable should be usable")
	suite.expect_eq(controller.quantities[&"potion"], 1, "consumable use must decrement quantity")
	controller.select_delta(1)
	suite.expect_true(controller.use_selected(), "wheel selection should change used consumable")
	suite.expect_eq(controller.quantities[&"bomb"], 0, "second slot quantity must decrement")
	controller.free()


func _run_character_tests() -> void:
	var definition := CharacterDef.new()
	definition.id = &"vanguard"
	definition.allowed_starting_families.assign([&"sword", &"spear"])
	definition.base_magic_power = 20.0
	var character_trait := CharacterTrait.new()
	character_trait.id = &"sword_mastery"
	character_trait.type = CharacterTrait.Type.CARD_FAMILY
	character_trait.family_id = &"sword"
	character_trait.family_weight_multiplier = 1.5
	character_trait.stat_modifiers = [{"stat": &"magic_power", "type": "percent", "value": 25.0}]
	character_trait.event_hooks.assign([&"before_card_execute"])
	character_trait.rule_values = {"bonus": 2}
	definition.traits.append(character_trait)
	var stats := CombatStatsComponent.new()
	var runtime := CharacterRuntime.new()
	runtime.initialize(definition, stats)
	suite.expect_true(definition.allows_family(&"sword"), "character should allow configured starting family")
	suite.expect_true(not definition.allows_family(&"fire"), "character should reject unavailable starting family")
	suite.expect_eq(stats.magic_power, 25.0, "character trait should modify base stats")
	suite.expect_eq(runtime.reward_weight_multiplier(&"sword"), 1.5, "family trait should affect reward weight")
	suite.expect_eq(runtime.dispatch(&"before_card_execute").size(), 1, "gimmick hook should return matching trait response")
	stats.free()


func _run_unlock_tests() -> void:
	var profile := UnlockProfile.new()
	profile.unlock("maps", &"foundry")
	suite.expect_true(profile.is_unlocked("maps", &"foundry"), "explicit unlock should persist in profile")
	profile.record_clear(&"foundry", &"sword", 2)
	suite.expect_true(profile.is_unlocked("endless_maps", &"foundry"), "map clear should unlock endless mode")
	var condition := UnlockCondition.new()
	condition.type = UnlockCondition.Type.CARD_FAMILY_CLEAR
	condition.target_id = &"sword"
	suite.expect_true(profile.evaluate("characters", &"duelist", condition), "met challenge should unlock character")
	var restored := UnlockProfile.from_dict(profile.to_dict())
	suite.expect_true(restored.is_unlocked("characters", &"duelist"), "unlock profile must serialize")


func _run_enemy_role_tests() -> void:
	var expected := [
		EnemyBehaviorDef.Action.MELEE_ATTACK,
		EnemyBehaviorDef.Action.PROJECTILE_ATTACK,
		EnemyBehaviorDef.Action.HEAL_ALLY,
		EnemyBehaviorDef.Action.SUMMON,
		EnemyBehaviorDef.Action.APPLY_DEBUFF,
		EnemyBehaviorDef.Action.CHARGE,
		EnemyBehaviorDef.Action.MELEE_ATTACK,
		EnemyBehaviorDef.Action.MELEE_ATTACK,
	]
	for role in EnemyDef.Role.values():
		suite.expect_eq(EnemyBrain.required_role_action(role), expected[role], "enemy role %d must map to its design action" % role)
	var support_def := EnemyDef.new()
	support_def.role = EnemyDef.Role.SUPPORT
	var heal := EnemyBehaviorDef.new()
	heal.id = &"heal"
	heal.action = EnemyBehaviorDef.Action.HEAL_ALLY
	heal.range = 999.0
	heal.priority = 10
	support_def.behavior_modules.append(heal)
	var brain := EnemyBrain.new()
	brain.initialize(support_def)
	suite.expect_eq(brain.tick(0.1, 20.0, true)["action"], EnemyBehaviorDef.Action.HEAL_ALLY, "support should heal an ally in need")


func _run_boss_pattern_tests() -> void:
	var strike := BossPatternDef.new()
	strike.id = &"strike"
	strike.telegraph_duration = 0.2
	strike.action_duration = 0.1
	var rage := BossPatternDef.new()
	rage.id = &"rage"
	rage.telegraph_duration = 0.1
	var phase_one := BossPhaseDef.new()
	phase_one.id = &"phase_one"
	phase_one.starts_at_health_ratio = 1.0
	phase_one.patterns.append(strike)
	var phase_two := BossPhaseDef.new()
	phase_two.id = &"phase_two"
	phase_two.starts_at_health_ratio = 0.5
	phase_two.patterns.append(rage)
	var boss := BossDef.new()
	boss.id = &"assembler"
	boss.phases.assign([phase_two, phase_one])
	var runner := BossPatternRunner.new()
	runner.initialize(boss, RunRng.new(9))
	suite.expect_eq(runner.tick(0.0, 1.0)["event"], "telegraph", "boss pattern must telegraph first")
	suite.expect_eq(runner.tick(0.21, 1.0)["event"], "execute", "boss pattern must execute after telegraph")
	runner.tick(0.11, 1.0)
	var phase_event := runner.tick(0.0, 0.4)
	suite.expect_eq(runner.phase_index, 1, "boss health threshold must advance phase")
	suite.expect_eq((phase_event["pattern"] as BossPatternDef).id, &"rage", "new phase must use its own pattern pool")


func _run_map_tests() -> void:
	var definition := MapDef.new()
	definition.id = &"foundry"
	definition.max_depth = 5
	definition.max_total_nodes = 12
	definition.choices_per_depth = 3
	var left := MapGenerator.generate(definition, RunRng.new(123))
	var right := MapGenerator.generate(definition, RunRng.new(123))
	suite.expect_true(left.validate(definition.max_total_nodes).is_empty(), "generated map must respect reachability and node limits")
	suite.expect_eq(left.nodes.size(), right.nodes.size(), "same seed must generate same map size")
	for node_id in left.nodes:
		suite.expect_eq(left.get_node(node_id).type, right.get_node(node_id).type, "same seed must generate same node types")
	var controller := RunMapController.new()
	controller.initialize(left)
	suite.expect_true(controller.available_nodes().size() <= 3, "a completed stage may expose at most three choices")
	suite.expect_true(controller.available_nodes().any(func(node): return node.type == MapNode.Type.COMBAT), "first map layer must always offer a combat node for automatic entry")
	var chosen := controller.available_nodes()[0]
	suite.expect_true(controller.select(chosen.id), "reachable node should be selectable")
	suite.expect_true(not controller.select(&"not_reachable"), "unreachable node must be rejected")


func _run_encounter_tests() -> void:
	var survive := EncounterObjective.new()
	survive.type = EncounterObjective.Type.SURVIVE
	survive.time_limit = 10.0
	var encounter := EncounterState.new()
	encounter.initialize(survive)
	suite.expect_eq(encounter.tick(9.9, true, 99), EncounterState.Result.RUNNING, "survival should run before timer")
	suite.expect_eq(encounter.tick(0.1, true, 99), EncounterState.Result.CLEARED, "survival should clear when timer reaches limit")
	var boss := EncounterObjective.new()
	boss.type = EncounterObjective.Type.BOSS
	boss.time_limit = 30.0
	encounter.initialize(boss)
	suite.expect_eq(encounter.tick(1.0, true, 0), EncounterState.Result.CLEARED, "boss node should clear when boss dies")
	encounter.initialize(boss)
	suite.expect_eq(encounter.tick(1.0, false, 1), EncounterState.Result.FAILED, "player death must fail encounter")
	encounter.initialize(boss)
	suite.expect_eq(encounter.tick(1.0, true, 1, true), EncounterState.Result.FAILED, "special mechanic failure must fail encounter")


func _run_node_service_tests() -> void:
	var session := RunSession.create(1, &"foundry", &"vanguard", &"sword")
	session.add_currency(100)
	var granted := [false]
	suite.expect_true(ShopService.purchase(session, 30, func(): granted[0] = true; return true), "valid shop purchase should succeed")
	suite.expect_true(granted[0], "shop purchase should grant item")
	suite.expect_eq(session.currency, 70, "shop purchase should spend exact currency")
	var event := EventDef.new()
	event.options = [{"currency_cost": 20, "currency_gain": 5, "result": {"card": "rare"}}]
	suite.expect_true(event.resolve(0, session)["success"], "affordable event option should resolve")
	suite.expect_eq(session.currency, 55, "event cost and reward should be atomic")
	var unlocks := UnlockProfile.new()
	suite.expect_true(not EndlessService.can_start(&"foundry", unlocks), "endless must be locked before clear")
	unlocks.record_clear(&"foundry", &"sword", 0)
	suite.expect_true(EndlessService.can_start(&"foundry", unlocks), "clear should unlock endless")
	suite.expect_true(EndlessService.difficulty_multiplier(2) > EndlessService.difficulty_multiplier(1), "endless loops must scale difficulty")


func _run_content_tests() -> void:
	var cards := ContentFactory.cards()
	var characters := ContentFactory.characters()
	suite.expect_eq(cards.size(), 48, "card roster must contain exactly 48 functional cards")
	var ids := {}
	var family_counts := {}
	for card in cards:
		suite.expect_true(not ids.has(card.id), "card IDs must be unique")
		ids[card.id] = true
		family_counts[card.family_id] = int(family_counts.get(card.family_id, 0)) + 1
		suite.expect_true(card.execution_interval > 0.0, "every card must define an execution delay")
		suite.expect_true(not card.effect_specs.is_empty(), "every card must define at least one executable effect")
		suite.expect_eq(card.targeting_labels().size(), 3, "every card must expose three targeting group labels")
	for family in [&"sword", &"spear", &"blunt", &"fire", &"water", &"poison"]:
		suite.expect_eq(int(family_counts.get(family, 0)), 8, "each family must contain exactly eight cards")
	var heavy_cards := cards.filter(func(card): return card.execution_interval >= 2.8)
	suite.expect_true(heavy_cards.size() >= 6, "each family must include a long-delay payoff card")
	for heavy_card in heavy_cards:
		suite.expect_true(heavy_card.execution_interval <= 3.6, "legendary delays must stay inside the faster parallel tempo")
		suite.expect_true(heavy_card.base_power >= 40.0 or heavy_card.summon_kind != &"", "long-delay cards must pay off with high power or a persistent construct")
	var meteor := cards.filter(func(card): return card.id == &"meteor_strike")[0] as CardDef
	suite.expect_true(meteor.effect_delay >= 2.0 and meteor.effect_delay <= 2.5, "meteor descent must preserve impact while fitting the faster parallel tempo")
	suite.expect_true(meteor.base_power >= 100.0, "meteor must deliver ultimate-class payoff")
	suite.expect_true(characters.any(func(character): return character.style == CharacterDef.Style.GENERAL), "content must include a general character")
	suite.expect_true(characters.any(func(character): return character.style == CharacterDef.Style.GIMMICK), "content must include a gimmick character")
	suite.expect_true(characters[0].base_combo_slots != characters[1].base_combo_slots, "playable characters must be able to define different base combo slot counts")
	suite.expect_eq(characters[1].combo_slot_count(1), characters[1].base_combo_slots + 1, "future relic modifiers must adjust the character combo slot count")
	suite.expect_eq(characters[1].combo_slot_count(-99), 1, "combo slot modifiers must retain at least one lane")
	var slash := cards.filter(func(card): return card.id == &"slash")[0] as CardDef
	var fireball := cards.filter(func(card): return card.id == &"fireball")[0] as CardDef
	suite.expect_true(slash.max_range > 0.0 and slash.max_range < 180.0, "melee slash must have a short finite maximum range")
	suite.expect_true(fireball.max_range > slash.max_range * 3.0, "projectile range must materially exceed melee range")
	suite.expect_eq(slash.attack_pattern, CardDef.AttackPattern.MELEE_ARC, "slash must use an arc spatial pattern")
	suite.expect_eq(fireball.attack_pattern, CardDef.AttackPattern.PROJECTILE, "fireball must use projectile travel")
	for character in characters:
		for family in character.allowed_starting_families:
			var deck_for_family := ContentFactory.starting_deck(family, cards)
			var cycle_for_family := ContentFactory.default_cycle(deck_for_family, character.combo_slot_count())
			suite.expect_true(ComboValidator.validate(deck_for_family, cycle_for_family)["valid"], "every starting family must produce a valid cycle")
			suite.expect_eq(cycle_for_family.combos.size(), mini(character.base_combo_slots, deck_for_family.cards.size()), "starting combo lane count must come from the selected character")
			suite.expect_eq(deck_for_family.cards.size(), 4, "every starting family must provide four opening cards")

func _run_survivor_tests() -> void:
	var progression := SurvivorProgression.new()
	suite.expect_eq(progression.level, 1, "survivor progression must start at level one")
	suite.expect_eq(progression.next_xp, 6.0, "first survivor level must require six XP")
	suite.expect_eq(progression.add_xp(5.0), 0, "XP below threshold must not level up")
	suite.expect_eq(progression.ratio(), 5.0 / 6.0, "survivor XP ratio must expose HUD progress")
	suite.expect_eq(progression.add_xp(2.0), 1, "crossing the XP threshold must report a level")
	suite.expect_eq(progression.level, 2, "survivor level must advance")
	suite.expect_eq(progression.xp, 1.0, "overflow XP must carry into the next level")
	suite.expect_eq(progression.next_xp, 9.0, "survivor XP threshold must scale per level")
	suite.expect_eq(SurvivorProgression.threshold_for(3), 11.0, "third survivor level must use the exponential XP curve")
	var early_growth := SurvivorProgression.threshold_for(3) - SurvivorProgression.threshold_for(2)
	var late_growth := SurvivorProgression.threshold_for(9) - SurvivorProgression.threshold_for(8)
	suite.expect_true(late_growth > early_growth, "XP requirements must accelerate rather than increase linearly")
	var survivor_session := RunSession.create(44, &"foundry", &"vanguard", &"sword", RunSession.Mode.SURVIVOR)
	survivor_session.relic_ids.append(&"vital_core")
	var restored := RunSession.from_dict(survivor_session.to_dict())
	suite.expect_eq(restored.mode, RunSession.Mode.SURVIVOR, "survivor mode must survive session serialization")
	suite.expect_true(restored.relic_ids.has(&"vital_core"), "survivor relic ownership must survive session serialization")
	var relics := ContentFactory.survivor_relics()
	suite.expect_true(relics.size() >= 6, "survivor reward pool must provide a varied relic set")
	suite.expect_true(relics.all(func(relic): return relic.has("stat") and relic.has("value")), "every survivor relic must contain an applicable stat effect")

func _run_persistence_tests() -> void:
	var session := RunSession.create(222, &"foundry", &"vanguard", &"sword")
	session.add_currency(75)
	session.combo_slot_modifier = -1
	var restored := SaveCodec.decode_run(SaveCodec.encode_run(session))
	suite.expect_true(restored != null, "encoded run must decode")
	suite.expect_eq(restored.currency, 75, "run save codec must preserve currency")
	suite.expect_eq(restored.combo_slot_modifier, -1, "run save codec must preserve combo slot modifiers")
	var legacy := {"seed": 9, "character_id": "legacy", "archetype_id": "fire", "currency": 12, "deck_state": []}
	var migrated := SaveCodec.decode_run(JSON.stringify(legacy))
	suite.expect_eq(migrated.starting_family_id, &"fire", "legacy archetype id must migrate to family id")
	suite.expect_eq(migrated.version, SaveCodec.CURRENT_VERSION, "legacy save must migrate to current version")
	suite.expect_eq(migrated.combo_slot_modifier, 0, "legacy saves must receive a neutral combo slot modifier")
	var profile := UnlockProfile.new()
	profile.unlock("characters", &"conduit")
	var decoded_profile := SaveCodec.decode_unlocks(SaveCodec.encode_unlocks(profile))
	suite.expect_true(decoded_profile.is_unlocked("characters", &"conduit"), "unlock save codec must preserve unlocks")


func _run_telemetry_tests() -> void:
	var session := RunSession.create(333, &"foundry", &"vanguard", &"sword")
	var telemetry := RunTelemetry.new()
	telemetry.begin(session)
	telemetry.record_card(&"slash")
	telemetry.record_card(&"slash")
	telemetry.record_node(MapNode.Type.COMBAT)
	telemetry.record_damage(&"slash", 42.5)
	telemetry.record_death(&"contact")
	var report := telemetry.report()
	suite.expect_eq(report["card_casts"][&"slash"], 2, "telemetry must aggregate card casts")
	suite.expect_eq(report["damage_by_source"][&"slash"], 42.5, "telemetry must aggregate damage")
	suite.expect_eq(report["seed"], 333, "telemetry report must include seed")


func _run_generation_stress_tests() -> void:
	var definition := ContentFactory.maps()[0]
	for seed in 100:
		var generated := MapGenerator.generate(definition, RunRng.new(seed + 1))
		suite.expect_true(generated.validate(definition.max_total_nodes).is_empty(), "stress map %d must remain valid" % seed)


func _run_script_parse_tests(path: StringName) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		suite.expect_true(false, "cannot scan script directory %s" % path)
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while entry != "":
		if entry not in [".", "..", ".godot", "game_description"]:
			var full_path := String(path).path_join(entry)
			if directory.current_is_dir():
				_run_script_parse_tests(StringName(full_path))
			elif entry.ends_with(".gd") and not full_path.ends_with("tests/test_runner.gd"):
				var script := load(full_path) as Script
				suite.expect_true(script != null and script.can_instantiate(), "script must parse: %s" % full_path)
		entry = directory.get_next()
	directory.list_dir_end()
