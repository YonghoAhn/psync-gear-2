extends RefCounted
class_name BattleTargetResolver

var arena: BattleArena
var rng: RunRng


func setup(owner_arena: BattleArena, run_rng: RunRng) -> void:
	arena = owner_arena
	rng = run_rng


func resolve(card_def: CardDef, origin: Vector2) -> Dictionary:
	var candidates: Array[BattleEnemy] = []
	if is_instance_valid(arena):
		candidates = arena.enemies_in_range_from(origin, maxf(0.0, card_def.max_range))
	var selected: Array[BattleEnemy] = []
	var point := origin
	if card_def.target_priority == CardDef.TargetPriority.SELF:
		return _result(selected, origin, origin, arena.player.facing_direction)
	if candidates.is_empty():
		return _result(selected, origin, origin, arena.player.facing_direction)
	match card_def.target_priority:
		CardDef.TargetPriority.LOWEST_HP:
			candidates.sort_custom(func(a: BattleEnemy, b: BattleEnemy):
				var ar := a.hp / maxf(1.0, a.max_hp)
				var br := b.hp / maxf(1.0, b.max_hp)
				return ar < br if not is_equal_approx(ar, br) else origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position)
			)
		CardDef.TargetPriority.RANDOM:
			_shuffle_deterministic(candidates)
		CardDef.TargetPriority.DENSEST_CLUSTER:
			var anchor := _densest_anchor(candidates, maxf(80.0, card_def.impact_radius))
			point = anchor.global_position
			candidates.sort_custom(func(a: BattleEnemy, b: BattleEnemy): return point.distance_squared_to(a.global_position) < point.distance_squared_to(b.global_position))
		_:
			candidates.sort_custom(func(a: BattleEnemy, b: BattleEnemy): return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position))
	var count := mini(maxi(1, card_def.target_count), candidates.size())
	for index in range(count):
		selected.append(candidates[index])
	if point == origin and not selected.is_empty():
		point = selected[0].global_position
	var aim := (point - origin).normalized()
	if aim == Vector2.ZERO:
		aim = arena.player.facing_direction
	return _result(selected, selected[0].global_position if not selected.is_empty() else origin, point, aim)


func _densest_anchor(candidates: Array[BattleEnemy], radius: float) -> BattleEnemy:
	var best := candidates[0]
	var best_count := -1
	for candidate in candidates:
		var count := 0
		for other in candidates:
			if candidate.global_position.distance_to(other.global_position) <= radius:
				count += 1
		if count > best_count:
			best = candidate
			best_count = count
	return best


func _shuffle_deterministic(items: Array[BattleEnemy]) -> void:
	for index in range(items.size() - 1, 0, -1):
		var swap_index := rng.randi_range(&"card_target", 0, index)
		var temp := items[index]
		items[index] = items[swap_index]
		items[swap_index] = temp


func _result(targets: Array[BattleEnemy], target_point: Vector2, effect_point: Vector2, aim: Vector2) -> Dictionary:
	return {
		"targets": targets,
		"target_point": target_point,
		"effect_point": effect_point,
		"aim": aim.normalized() if aim != Vector2.ZERO else Vector2.RIGHT,
	}
