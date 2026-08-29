extends Node2D
class_name BattleArena

signal completed(success: bool, summary: Dictionary)
signal survivor_level_up_requested(level: int, xp: float, next_xp: float)
signal survivor_currency_changed(amount: int, total: int)

const WORLD_RECT := Rect2(0, 0, 2560, 1440)
const SPAWN_WARNING_DURATION := 1.0
const COMBO_FAMILY_DAMAGE_STEP := 0.05

var node_type: MapNode.Type
var player: BattlePlayer
var deck: DeckState
var cycle: CycleState
var runner := CycleRunner.new()
var elapsed := 0.0
var duration := 20.0
var spawn_timer := 0.0
var kills := 0
var ended := false
var difficulty := 1.0
var rng: RunRng
var hud: BattleHud
var camera: Camera2D
var shake_left := 0.0
var shake_strength := 0.0
var pending_spawn_count := 0
var pending_card_effects := 0
var card_effect_generation := 0
var survivor_mode := false
var survivor_progression := SurvivorProgression.new()
var survivor_power_multiplier := 1.0
var survivor_attack_speed_multiplier := 1.0
var survivor_xp_multiplier := 1.0
var survivor_relics: Array[Dictionary] = []
var survivor_currency := 0
var survivor_level_up_pending := false
var survivor_boss_queued := false
var target_resolver := BattleTargetResolver.new()
var card_executor := BattleCardExecutor.new()
var family_tiers: Dictionary = {}
var status_caps := {&"burning": 5, &"poisoned": 8}
var active_card_spawns: Dictionary = {}
var flaming_weapon_left := 0.0
var enemy_defs: Array[EnemyDef] = []
var named_enemy_defs: Array[EnemyDef] = []
var boss_enemy_defs: Array[EnemyDef] = []
var family_cast_counts: Dictionary = {}
var combo_last_families: Dictionary = {}
var combo_family_chain_counts: Dictionary = {}
var combo_family_damage_multipliers: Dictionary = {}
var queued_survivor_deck: DeckState
var queued_survivor_cycle: CycleState

func initialize(type: MapNode.Type, character: CharacterDef, run_deck: DeckState, run_cycle: CycleState, difficulty_scale := 1.0, run_rng: RunRng = null) -> void:
	node_type = type
	deck = run_deck
	cycle = run_cycle
	difficulty = difficulty_scale
	rng = run_rng if run_rng else RunRng.new(1)
	duration = 28.0 if type == MapNode.Type.ELITE else 22.0
	_build_arena(character)
	_configure_card_system()
	if type == MapNode.Type.BOSS:
		var boss := boss_enemy_defs[0] if not boss_enemy_defs.is_empty() else null
		spawn_enemy(EnemyDef.Role.DISRUPTOR, true, boss)
	elif type == MapNode.Type.ELITE:
		var named := named_enemy_defs[rng.randi_range(&"enemy_roster", 0, named_enemy_defs.size() - 1)]
		spawn_enemy(named.role, false, named)
		spawn_enemy(EnemyDef.Role.MELEE)
	else:
		spawn_enemy(EnemyDef.Role.MELEE)
		spawn_enemy(EnemyDef.Role.RANGED)
	# 시작 직후 추가 웨이브가 겹치지 않도록 첫 정규 스폰까지 여유를 둔다.
	spawn_timer = 4.2
	runner.configure(deck, cycle, _execute_card)
	runner.card_executed.connect(_on_card_executed)
	runner.combo_changed.connect(_on_combo_changed)
	runner.configuration_applied.connect(_on_runner_configuration_applied)
	runner.start()

func initialize_survivor(character: CharacterDef, run_deck: DeckState, run_cycle: CycleState, run_rng: RunRng = null, starting_currency := 0) -> void:
	survivor_mode = true
	survivor_currency = maxi(0, starting_currency)
	node_type = MapNode.Type.COMBAT
	deck = run_deck
	cycle = run_cycle
	difficulty = 1.0
	rng = run_rng if run_rng else RunRng.new(1)
	survivor_progression = SurvivorProgression.new()
	_build_arena(character)
	_configure_card_system()
	spawn_enemy(EnemyDef.Role.MELEE)
	spawn_enemy(EnemyDef.Role.RANGED)
	spawn_enemy(EnemyDef.Role.SUPPORT)
	spawn_timer = 3.2
	runner.configure(deck, cycle, _execute_card)
	runner.card_executed.connect(_on_card_executed)
	runner.combo_changed.connect(_on_combo_changed)
	runner.configuration_applied.connect(_on_runner_configuration_applied)
	runner.start()
	hud.set_survivor_progress(survivor_progression.level, survivor_progression.xp, survivor_progression.next_xp, elapsed, kills)
	hud.set_currency(survivor_currency)


func _build_arena(character: CharacterDef) -> void:
	var background := TextureRect.new()
	background.texture = load("res://assets/arena_foundry.png")
	background.position = WORLD_RECT.position
	background.size = WORLD_RECT.size
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.modulate = Color("725b78")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	player = BattlePlayer.new()
	player.position = WORLD_RECT.get_center()
	player.setup(character)
	player.arena_rect = WORLD_RECT.grow(-52.0)
	player.died.connect(_on_player_died)
	player.health_changed.connect(_on_health_changed)
	add_child(player)
	camera = Camera2D.new()
	camera.name = "PlayerCamera"
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = int(WORLD_RECT.position.x)
	camera.limit_top = int(WORLD_RECT.position.y)
	camera.limit_right = int(WORLD_RECT.end.x)
	camera.limit_bottom = int(WORLD_RECT.end.y)
	camera.limit_smoothed = true
	player.add_child(camera)
	_build_hud()

func _build_hud() -> void:
	hud = BattleHud.new()
	hud.name = "BattleHud"
	add_child(hud)
	hud.setup(player, deck, cycle)

func _process(delta: float) -> void:
	if ended:
		return
	elapsed += delta
	flaming_weapon_left = maxf(0.0, flaming_weapon_left - delta)
	spawn_timer -= delta
	runner.tick(delta, survivor_attack_speed_multiplier if survivor_mode else 1.0)
	hud.set_card_cooldowns(runner.cooldown_snapshots())
	var enemy_cap := 18 if survivor_mode else 12
	if node_type != MapNode.Type.BOSS and spawn_timer <= 0.0 and _active_enemy_count() + pending_spawn_count < enemy_cap:
		spawn_enemy(_next_spawn_role())
		if survivor_mode:
			difficulty = 1.0 + elapsed * 0.006 + survivor_progression.level * 0.04
			spawn_timer = maxf(0.72, 2.65 - elapsed * 0.008)
		else:
			spawn_timer = maxf(1.55, 3.45 - elapsed * 0.025)
	if survivor_mode:
		hud.set_survivor_progress(survivor_progression.level, survivor_progression.xp, survivor_progression.next_xp, elapsed, kills)
		hud.set_currency(survivor_currency)
	else:
		hud.set_time(duration - elapsed)
		hud.set_objective(kills)
	if shake_left > 0.0:
		shake_left -= delta
		camera.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	else:
		camera.offset = Vector2.ZERO
	if not survivor_mode and node_type != MapNode.Type.BOSS and elapsed >= duration:
		_finish(true)

func spawn_enemy(role: EnemyDef.Role, boss := false, definition: EnemyDef = null) -> void:
	if ended:
		return
	var spawn_position := _choose_spawn_position(boss)
	var marker := SpawnWarningMarker.new()
	add_child(marker)
	marker.setup(spawn_position, role, boss, SPAWN_WARNING_DURATION)
	pending_spawn_count += 1
	var spawn_delay := Timer.new()
	spawn_delay.one_shot = true
	spawn_delay.wait_time = SPAWN_WARNING_DURATION
	add_child(spawn_delay)
	spawn_delay.timeout.connect(func(): _materialize_enemy(role, boss, spawn_position, definition); spawn_delay.queue_free())
	spawn_delay.start()


func _materialize_enemy(role: EnemyDef.Role, boss: bool, spawn_position: Vector2, definition: EnemyDef = null) -> void:
	pending_spawn_count = maxi(0, pending_spawn_count - 1)
	if ended:
		return
	var enemy := BattleEnemy.new()
	enemy.position = spawn_position
	enemy.setup(role, player, self, difficulty, boss, definition)
	enemy.defeated.connect(_on_enemy_defeated)
	add_child(enemy)
	spawn_hostile_vfx(CombatVfx.Kind.RING, enemy.position, ArtDirection.MAGENTA, 52.0, 0.45)


func _choose_spawn_position(boss: bool) -> Vector2:
	var safe_bounds := WORLD_RECT.grow(-90.0)
	var angle := rng.randf(&"combat_spawn") * TAU
	var distance := lerpf(430.0, 550.0 if not boss else 500.0, rng.randf(&"combat_spawn"))
	var candidate := player.global_position + Vector2.from_angle(angle) * distance
	return Vector2(
		clampf(candidate.x, safe_bounds.position.x, safe_bounds.end.x),
		clampf(candidate.y, safe_bounds.position.y, safe_bounds.end.y)
	)



func _next_spawn_role() -> EnemyDef.Role:
	var pool: Array[EnemyDef.Role] = [EnemyDef.Role.MELEE, EnemyDef.Role.RANGED]
	if elapsed >= 8.0 or kills >= 4 or survivor_progression.level >= 2:
		pool.append_array([EnemyDef.Role.CHARGER, EnemyDef.Role.BOMBER, EnemyDef.Role.SHIELD])
	if elapsed >= 16.0 or kills >= 10 or survivor_progression.level >= 4:
		pool.append_array([EnemyDef.Role.SUPPORT, EnemyDef.Role.SUMMONER, EnemyDef.Role.DISRUPTOR])
	var role := pool[rng.randi_range(&"enemy_roster", 0, pool.size() - 1)]
	if role in [EnemyDef.Role.SUPPORT, EnemyDef.Role.SUMMONER] and _role_count(role) >= 1:
		return EnemyDef.Role.MELEE
	return role


func _role_count(role: EnemyDef.Role) -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group(&"battle_enemy"):
		var enemy := node as BattleEnemy
		if is_instance_valid(enemy) and enemy.role == role:
			count += 1
	return count

func _active_enemy_count() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group(&"battle_enemy"):
		if node is BattleEnemy and is_instance_valid(node):
			count += 1
	return count

func heal_random_enemy(amount: float) -> void:
	heal_nearby_enemies(player.global_position, 3000.0, amount)

func heal_nearby_enemies(at: Vector2, radius: float, amount: float) -> void:
	for node in get_tree().get_nodes_in_group(&"battle_enemy"):
		var enemy := node as BattleEnemy
		if is_instance_valid(enemy) and enemy.global_position.distance_to(at) <= radius:
			enemy.heal(amount)

func _execute_card(card: CardInstance) -> void:
	if card.card_def == null or ended:
		return
	var context := card_executor.build_context(card)
	var family := card.card_def.family_id
	var combo_index := runner.current_position().x
	var combo_id := cycle.combos[combo_index].id if cycle != null and combo_index >= 0 and combo_index < cycle.combos.size() else StringName("combo_%d" % combo_index)
	var family_multiplier := _advance_combo_family_chain(combo_id, family)
	context["power"] = float(context["power"]) * family_multiplier
	context["combo_family_multiplier"] = family_multiplier
	context["combo_family_chain_count"] = int(combo_family_chain_counts.get(combo_id, 1))
	family_cast_counts[family] = int(family_cast_counts.get(family, 0)) + 1
	context["echo"] = family == &"sword" and int(family_tiers.get(family, 0)) >= 2 and int(family_cast_counts[family]) % 3 == 0
	if card.card_def.effect_delay <= 0.0:
		_resolve_card_effect(card, context)
	else:
		_queue_card_effect(card, context)


func _advance_combo_family_chain(combo_id: StringName, family_id: StringName) -> float:
	var chain_count := 1
	if StringName(combo_last_families.get(combo_id, &"")) == family_id:
		chain_count = int(combo_family_chain_counts.get(combo_id, 0)) + 1
	combo_last_families[combo_id] = family_id
	combo_family_chain_counts[combo_id] = chain_count
	var multiplier := 1.0 + float(chain_count - 1) * COMBO_FAMILY_DAMAGE_STEP
	combo_family_damage_multipliers[combo_id] = multiplier
	return multiplier


func combo_family_damage_multiplier(combo_id: StringName) -> float:
	return float(combo_family_damage_multipliers.get(combo_id, 1.0))


func _queue_card_effect(card: CardInstance, context: Dictionary) -> void:
	var def := card.card_def
	var generation := card_effect_generation
	var effect_point: Vector2 = context["effect_point"]
	var color: Color = context["color"]
	var telegraph_radius := maxf(52.0, def.impact_radius)
	if def.id == &"meteor_strike":
		var meteor := MeteorStrikeVfx.new()
		add_child(meteor)
		meteor.setup(effect_point, telegraph_radius, def.effect_delay)
	else:
		spawn_vfx(CombatVfx.Kind.TELEGRAPH, effect_point, color, telegraph_radius, def.effect_delay)
	spawn_vfx(CombatVfx.Kind.RING, context["origin"], color, 46.0, 0.28)
	pending_card_effects += 1
	var effect_timer := Timer.new()
	effect_timer.name = "CardEffect_%s" % def.id
	effect_timer.one_shot = true
	effect_timer.wait_time = def.effect_delay
	add_child(effect_timer)
	effect_timer.timeout.connect(func():
		pending_card_effects = maxi(0, pending_card_effects - 1)
		if not ended and generation == card_effect_generation and is_instance_valid(player):
			_resolve_card_effect(card, context)
		effect_timer.queue_free()
	)
	effect_timer.start()

func _resolve_card_effect(card: CardInstance, context: Dictionary) -> void:
	card_executor.resolve(card, context)
	if bool(context.get("echo", false)) and bool(context.get("has_target", false)):
		var echo_context := context.duplicate(true)
		echo_context["echo"] = false
		echo_context["power"] = float(echo_context["power"]) * 0.45
		var echo_timer := Timer.new()
		echo_timer.one_shot = true
		echo_timer.wait_time = 0.16
		add_child(echo_timer)
		echo_timer.timeout.connect(func():
			if not ended:
				card_executor.resolve(card, echo_context)
			echo_timer.queue_free()
		)
		echo_timer.start()


func _enemies_in_range_from(at: Vector2, max_range: float) -> Array[BattleEnemy]:
	var result: Array[BattleEnemy] = []
	for node in get_tree().get_nodes_in_group(&"battle_enemy"):
		var enemy := node as BattleEnemy
		if is_instance_valid(enemy) and at.distance_to(enemy.global_position) <= max_range:
			result.append(enemy)
	return result
func _enemies_in_range(max_range: float) -> Array[BattleEnemy]:
	return _enemies_in_range_from(player.global_position, max_range)


func spawn_player_projectile(at: Vector2, direction: Vector2, damage: float, color: Color, speed := 650.0, size := 9.0, context: Dictionary = {}, pierce := 0, max_distance := 0.0) -> void:
	var projectile := BattleProjectile.new()
	add_child(projectile)
	projectile.setup(self, at, direction, speed, damage, false, color, size, context, pierce, max_distance)

func spawn_enemy_projectile(at: Vector2, direction: Vector2, damage: float, color: Color, speed := 350.0) -> void:
	var projectile := BattleProjectile.new()
	add_child(projectile)
	projectile.setup(self, at, direction, speed, damage, true, color, 9.0)

func spawn_delayed_enemy_projectile(at: Vector2, direction: Vector2, damage: float, color: Color, speed: float, delay: float) -> void:
	if delay <= 0.0:
		spawn_enemy_projectile(at, direction, damage, color, speed)
		return
	var projectile_delay := Timer.new()
	projectile_delay.one_shot = true
	projectile_delay.wait_time = delay
	add_child(projectile_delay)
	projectile_delay.timeout.connect(func():
		if not ended:
			spawn_enemy_projectile(at, direction, damage, color, speed)
		projectile_delay.queue_free()
	)
	projectile_delay.start()

func spawn_hostile_zone(at: Vector2, radius: float, damage: float, life: float) -> void:
	var zone := BattleHazard.new()
	add_child(zone)
	zone.setup(self, at, radius, damage, life, true, ArtDirection.DANGER)

func spawn_friendly_zone(at: Vector2, radius: float, damage: float, life: float, color: Color, context: Dictionary = {}, source_id: StringName = &"", active_limit := 2) -> void:
	var zone := BattleHazard.new()
	add_child(zone)
	zone.setup(self, at, radius, damage, life, false, color, context)
	register_card_spawn(zone, source_id, active_limit)

func spawn_vfx(kind: CombatVfx.Kind, at: Vector2, color: Color, size: float, life: float, aim := Vector2.RIGHT, arc := 100.0) -> void:
	add_child(CombatVfx.create(kind, at, color, size, life, aim, arc, CombatVfx.Side.FRIENDLY))

func spawn_hostile_vfx(kind: CombatVfx.Kind, at: Vector2, color: Color, size: float, life: float, aim := Vector2.RIGHT, arc := 100.0) -> void:
	add_child(CombatVfx.create(kind, at, color, size, life, aim, arc, CombatVfx.Side.HOSTILE))

func impact(at: Vector2, color: Color, size: float, hostile := false) -> void:
	if hostile:
		spawn_hostile_vfx(CombatVfx.Kind.IMPACT, at, color, size, 0.3)
	else:
		spawn_vfx(CombatVfx.Kind.IMPACT, at, color, size, 0.3)
	shake(2.5, 0.08)

func shake(strength: float, seconds: float) -> void:
	shake_strength = maxf(shake_strength, strength)
	shake_left = maxf(shake_left, seconds)


func _configure_card_system() -> void:
	family_tiers = SynergyResolver.set_tiers(deck)
	status_caps[&"burning"] = 5
	enemy_defs = ContentFactory.enemies()
	named_enemy_defs = ContentFactory.named_enemies()
	boss_enemy_defs = ContentFactory.bosses()
	if int(family_tiers.get(&"fire", 0)) >= 2:
		status_caps[&"burning"] = 7
	target_resolver.setup(self, rng)
	card_executor.setup(self, target_resolver)


func enemies_in_range_from(at: Vector2, max_range: float) -> Array[BattleEnemy]:
	return _enemies_in_range_from(at, max_range)


func damage_area(at: Vector2, radius: float, damage: float, context: Dictionary = {}, excluded: BattleEnemy = null) -> void:
	for enemy in _enemies_in_range_from(at, radius):
		if enemy != excluded:
			enemy.take_damage(damage, context)


func trigger_reaction(reaction_id: StringName, source: BattleEnemy, power: float) -> void:
	if not is_instance_valid(source):
		return
	if int(family_tiers.get(&"water", 0)) >= 3:
		power *= 1.25
	var reaction_context := {"origin": source.global_position, "source_power": power}
	match reaction_id:
		&"steam_burst":
			spawn_vfx(CombatVfx.Kind.IMPACT, source.global_position, Color("e9f7ff"), 100.0, 0.45)
			for enemy in _enemies_in_range_from(source.global_position, 100.0):
				enemy.take_damage(power, reaction_context)
				enemy.apply_impulse(source.global_position.direction_to(enemy.global_position) * 125.0)
		&"contamination":
			spawn_vfx(CombatVfx.Kind.RING, source.global_position, Color("91d63b"), 150.0, 0.5)
			var spread := _enemies_in_range_from(source.global_position, 150.0)
			spread.erase(source)
			for index in range(mini(3, spread.size())):
				spread[index].apply_status(&"poisoned", 2, 6.0, power)
		&"toxic_ignite":
			spawn_vfx(CombatVfx.Kind.IMPACT, source.global_position, Color("ff8a34"), 90.0, 0.5)
			damage_area(source.global_position, 90.0, power, reaction_context)
		&"chain_shock":
			spawn_vfx(CombatVfx.Kind.RING, source.global_position, ArtDirection.YELLOW, 220.0, 0.45)
			var chained := _enemies_in_range_from(source.global_position, 220.0)
			chained.erase(source)
			for index in range(mini(4, chained.size())):
				chained[index].take_damage(power, reaction_context)


func spawn_card_construct(card: CardInstance, at: Vector2, power: float, color: Color, context: Dictionary) -> void:
	var card_def := card.card_def
	var spawn_at := at if at != Vector2.ZERO else player.global_position + player.facing_direction * 52.0
	if card_def.summon_kind in [&"golem", &"spirit"]:
		var summon := BattleSummon.new()
		add_child(summon)
		summon.setup(self, card.instance_id, card_def.summon_kind, spawn_at, power, card_def.impact_radius, color, context)
		register_card_spawn(summon, card.instance_id, maxi(1, card_def.active_limit))
	else:
		var installation := BattleInstallation.new()
		add_child(installation)
		installation.setup(self, card.instance_id, card_def.summon_kind, spawn_at, power, maxf(160.0, card_def.max_range), color, context)
		register_card_spawn(installation, card.instance_id, maxi(1, card_def.active_limit))


func register_card_spawn(node: Node, source_id: StringName, limit: int) -> void:
	if source_id == &"" or limit <= 0:
		return
	if not active_card_spawns.has(source_id):
		active_card_spawns[source_id] = []
	var entries: Array = active_card_spawns[source_id]
	for index in range(entries.size() - 1, -1, -1):
		if not is_instance_valid(entries[index]):
			entries.remove_at(index)
	while entries.size() >= limit:
		var oldest: Node = entries.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	entries.append(node)
	active_card_spawns[source_id] = entries


func on_enemy_status_death(enemy: BattleEnemy) -> void:
	if enemy.has_status(&"burning") and int(family_tiers.get(&"fire", 0)) >= 3:
		spawn_vfx(CombatVfx.Kind.IMPACT, enemy.global_position, Color("ff6b35"), 95.0, 0.45)
		damage_area(enemy.global_position, 95.0, 18.0, {"origin": enemy.global_position, "source_power": 18.0}, enemy)
	if enemy.has_status(&"poisoned") and int(family_tiers.get(&"poison", 0)) >= 2:
		for other in _enemies_in_range_from(enemy.global_position, 150.0):
			if other != enemy:
				other.apply_status(&"poisoned", 2, 6.0, 12.0)

func _family_color(family: StringName) -> Color:
	return ArtDirection.family_color(family)

func _on_card_executed(card: CardInstance, combo_index: int, _card_index: int) -> void:
	hud.activate_card(combo_index, _card_index)

func _on_combo_changed(combo_index: int) -> void:
	hud.show_combo(combo_index)

func _on_enemy_defeated(enemy: BattleEnemy) -> void:
	kills += 1
	if survivor_mode:
		var currency_gain := 10 if enemy.is_boss else 3 if enemy.is_named else 1
		survivor_currency += currency_gain
		hud.set_currency(survivor_currency)
		survivor_currency_changed.emit(currency_gain, survivor_currency)
		var xp_amount := (5.0 if enemy.is_boss else 3.0 if enemy.is_named else 1.0) * survivor_xp_multiplier
		var levels_gained := survivor_progression.add_xp(xp_amount)
		if levels_gained > 0 and not survivor_level_up_pending:
			survivor_level_up_pending = true
			survivor_boss_queued = survivor_progression.level % 5 == 0
			survivor_level_up_requested.emit(survivor_progression.level, survivor_progression.xp, survivor_progression.next_xp)
	elif enemy.is_boss:
		_finish(true)

func queue_survivor_cycle(new_deck: DeckState, new_cycle: CycleState) -> bool:
	if not survivor_mode or not ComboValidator.validate(new_deck, new_cycle)["valid"]:
		return false
	queued_survivor_deck = new_deck
	queued_survivor_cycle = new_cycle
	if runner.queue_configuration(new_deck, new_cycle):
		return true
	queued_survivor_deck = null
	queued_survivor_cycle = null
	return false


func _on_runner_configuration_applied(applied_deck: DeckState, applied_cycle: CycleState) -> void:
	deck = applied_deck
	cycle = applied_cycle
	queued_survivor_deck = null
	queued_survivor_cycle = null
	_configure_card_system()
	hud.combo_rail.setup(deck, cycle)


func apply_survivor_relic(relic: Dictionary) -> void:
	if not survivor_mode:
		return
	var relic_id := StringName(relic.get("id", ""))
	for owned in survivor_relics:
		if StringName(owned.get("id", "")) == relic_id:
			return
	survivor_relics.append(relic.duplicate(true))
	match String(relic.get("stat", "")):
		"max_hp":
			var amount := float(relic.get("value", 0.0))
			player.max_hp += amount
			player.hp += amount
			player.health_changed.emit(player.hp, player.max_hp, player.shield)
		"attack_speed":
			survivor_attack_speed_multiplier += float(relic.get("value", 0.0))
		"power":
			survivor_power_multiplier += float(relic.get("value", 0.0))
		"move_speed":
			player.move_speed += float(relic.get("value", 0.0))
		"xp":
			survivor_xp_multiplier += float(relic.get("value", 0.0))
		"shield":
			player.grant_shield(float(relic.get("value", 0.0)))
	hud.set_relics(survivor_relics)


func resume_survivor_after_levelup() -> void:
	survivor_level_up_pending = false
	if survivor_boss_queued:
		survivor_boss_queued = false
		if survivor_progression.level % 10 == 0:
			var boss := boss_enemy_defs[0] if not boss_enemy_defs.is_empty() else null
			spawn_enemy(EnemyDef.Role.DISRUPTOR, true, boss)
		else:
			var named := named_enemy_defs[rng.randi_range(&"enemy_roster", 0, named_enemy_defs.size() - 1)]
			spawn_enemy(named.role, false, named)


func _on_health_changed(hp: float, maximum: float, shield: float) -> void:
	hud.set_health(hp, maximum, shield)

func _on_player_died() -> void:
	_finish(false)

func _finish(success: bool) -> void:
	if ended:
		return
	ended = true
	card_effect_generation += 1
	pending_card_effects = 0
	runner.stop()
	completed.emit(success, {
		"kills": kills,
		"elapsed": elapsed,
		"node_type": node_type,
		"survivor_mode": survivor_mode,
		"level": survivor_progression.level if survivor_mode else 0,
		"relics": survivor_relics.size(),
		"currency": survivor_currency,
		"reason": "체력 0" if not success else "",
	})
