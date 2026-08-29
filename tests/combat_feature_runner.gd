extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred(&"_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _card(cards: Array[CardDef], id: StringName) -> CardDef:
	for card in cards:
		if card.id == id:
			return card
	return null


func _spawn_test_enemy(arena: BattleArena, at: Vector2, hp_ratio := 1.0) -> BattleEnemy:
	var enemy := BattleEnemy.new()
	enemy.position = at
	enemy.setup(EnemyDef.Role.MELEE, arena.player, arena, 1.0)
	enemy.hp = enemy.max_hp * hp_ratio
	arena.add_child(enemy)
	return enemy


func _target_card(priority: CardDef.TargetPriority, count := 1, radius := 100.0) -> CardDef:
	var definition := CardDef.new()
	definition.id = StringName("target_%d" % priority)
	definition.target_priority = priority
	definition.target_count = count
	definition.max_range = 700.0
	definition.impact_radius = radius
	definition.base_power = 1.0
	definition.execution_interval = 0.5
	return definition


func _run() -> void:
	var cards := ContentFactory.cards()
	var character := ContentFactory.characters()[0]
	var deck := ContentFactory.starting_deck(&"sword", cards)
	var cycle := ContentFactory.default_cycle(deck)
	var arena := BattleArena.new()
	root.add_child(arena)
	arena.initialize(MapNode.Type.COMBAT, character, deck, cycle, 1.0, RunRng.new(9191))
	await process_frame
	arena.runner.stop()
	var origin := arena.player.global_position
	var near := _spawn_test_enemy(arena, origin + Vector2(90, 0), 1.0)
	var low := _spawn_test_enemy(arena, origin + Vector2(350, 0), 0.18)
	var cluster_a := _spawn_test_enemy(arena, origin + Vector2(380, 25), 0.8)
	var cluster_b := _spawn_test_enemy(arena, origin + Vector2(410, -20), 0.7)
	await process_frame

	var nearest_result := arena.target_resolver.resolve(_target_card(CardDef.TargetPriority.NEAREST), origin)
	_expect((nearest_result["targets"] as Array)[0] == near, "nearest targeting must choose the closest in-range enemy")
	var lowest_result := arena.target_resolver.resolve(_target_card(CardDef.TargetPriority.LOWEST_HP), origin)
	_expect((lowest_result["targets"] as Array)[0] == low, "lowest-HP targeting must sort by HP ratio")
	var dense_result := arena.target_resolver.resolve(_target_card(CardDef.TargetPriority.DENSEST_CLUSTER, 1, 90.0), origin)
	_expect((dense_result["effect_point"] as Vector2).distance_to(low.global_position) < 100.0, "densest targeting must anchor on the largest local cluster")
	var random_a := BattleTargetResolver.new()
	random_a.setup(arena, RunRng.new(77))
	var random_b := BattleTargetResolver.new()
	random_b.setup(arena, RunRng.new(77))
	var random_def := _target_card(CardDef.TargetPriority.RANDOM, 3)
	var random_targets_a: Array = random_a.resolve(random_def, origin)["targets"]
	var random_targets_b: Array = random_b.resolve(random_def, origin)["targets"]
	var random_positions_a := random_targets_a.map(func(enemy): return enemy.global_position)
	var random_positions_b := random_targets_b.map(func(enemy): return enemy.global_position)
	_expect(random_positions_a == random_positions_b, "random targeting must be reproducible through the dedicated RunRng stream")

	near.statuses.clear()
	near.reaction_cooldown = 0.0
	near.apply_status(&"wet", 1, 4.0, 20.0)
	near.take_damage(0.0, {"status_id": &"burning", "status_stacks": 2, "status_duration": 4.0, "source_power": 20.0, "origin": origin})
	_expect(not near.has_status(&"wet") and near.status_stacks(&"burning") == 1, "steam burst must consume wet and one burning stack")

	near.statuses.clear()
	near.reaction_cooldown = 0.0
	cluster_a.global_position = near.global_position + Vector2(80, 0)
	for enemy in [low, cluster_a, cluster_b]:
		enemy.statuses.clear()
	near.apply_status(&"wet", 1, 4.0, 20.0)
	near.take_damage(0.0, {"status_id": &"poisoned", "status_stacks": 1, "status_duration": 6.0, "source_power": 20.0, "origin": origin})
	_expect(not near.has_status(&"wet") and [low, cluster_a, cluster_b].any(func(enemy): return enemy.status_stacks(&"poisoned") >= 2), "contamination must consume wet and spread poison")

	near.statuses.clear()
	near.reaction_cooldown = 0.0
	near.apply_status(&"burning", 2, 4.0, 20.0)
	near.take_damage(0.0, {"status_id": &"poisoned", "status_stacks": 2, "status_duration": 6.0, "source_power": 20.0, "origin": origin})
	_expect(near.status_stacks(&"burning") == 1 and near.status_stacks(&"poisoned") == 1, "toxic ignition must consume one stack of both statuses")

	near.statuses.clear()
	near.reaction_cooldown = 0.0
	var chain_hp := cluster_a.hp
	near.apply_status(&"wet", 1, 4.0, 20.0)
	near.take_damage(0.0, {"status_id": &"shocked", "status_stacks": 1, "status_duration": 2.0, "source_power": 20.0, "origin": origin})
	_expect(not near.has_status(&"wet") and cluster_a.hp < chain_hp, "chain shock must consume wet and damage nearby enemies")

	var turret_card := CardInstance.create(_card(cards, &"trench_trooper"), &"test")
	var construct_context := {"origin": origin, "source_power": 12.0}
	arena.spawn_card_construct(turret_card, origin + Vector2(50, 50), 12.0, ArtDirection.VIOLET, construct_context)
	arena.spawn_card_construct(turret_card, origin + Vector2(80, 50), 12.0, ArtDirection.VIOLET, construct_context)
	await process_frame
	var turret_count := 0
	for node in get_nodes_in_group(&"battle_card_spawn"):
		if node is BattleInstallation and node.source_id == turret_card.instance_id:
			turret_count += 1
	_expect(turret_count == 1, "installation active limit must replace the oldest construct")

	arena.survivor_mode = true
	arena.player.max_hp = 100000.0
	arena.player.hp = arena.player.max_hp
	arena.runner.start()
	for step in range(300):
		arena._process(0.1)
		if step % 30 == 0:
			await process_frame
	arena.runner.stop()
	_expect(arena.elapsed >= 30.0 and not arena.ended, "accelerated 30-second auto combat must remain stable")
	_expect(arena.get_child_count() < 1000, "auto combat must not create an unbounded number of nodes")

	arena._finish(false)
	arena.queue_free()
	await process_frame
	if failures.is_empty():
		print("COMBAT FEATURE PASS: targeting, reactions, limits, 30s simulation")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("COMBAT FEATURE FAIL: %d failures" % failures.size())
		quit(1)
