extends RefCounted
class_name TargetResolver

var _scene_tree: SceneTree


func setup(tree: SceneTree) -> void:
	_scene_tree = tree


func resolve(spec: TargetSpec, caster: EntityBase) -> Dictionary:
	var result := {"entities": [], "positions": [], "direction": Vector2.RIGHT}
	if caster == null:
		return {}
	if spec == null:
		result["entities"] = [caster]
		result["positions"] = [caster.global_position]
		return result
	var enemies := _living_enemies()
	match spec.type:
		TargetSpec.Type.MOUSE_DIRECTION:
			var nearest := _nearest(caster, enemies, spec.range)
			if nearest:
				result["entities"] = [nearest]
				result["positions"] = [nearest.global_position]
				result["direction"] = caster.global_position.direction_to(nearest.global_position)
			else:
				result["positions"] = [caster.global_position]
		TargetSpec.Type.MOUSE_POSITION, TargetSpec.Type.INSTALL_POINT, TargetSpec.Type.DENSEST_CLUSTER:
			var densest := _densest(enemies, maxf(80.0, spec.range * 0.3))
			result["entities"] = [densest] if densest else []
			result["positions"] = [densest.global_position] if densest else [caster.global_position]
		TargetSpec.Type.SELF:
			result["entities"] = [caster]
			result["positions"] = [caster.global_position]
		TargetSpec.Type.NEAREST_ENEMY:
			var nearest := _nearest(caster, enemies, spec.range)
			if nearest:
				result["entities"] = [nearest]
				result["positions"] = [nearest.global_position]
		TargetSpec.Type.RANDOM_ENEMIES:
			enemies.shuffle()
			result["entities"] = enemies.slice(0, mini(spec.count, enemies.size()))
			result["positions"] = result["entities"].map(func(enemy): return enemy.global_position)
		TargetSpec.Type.ALL_ENEMIES_IN_RANGE:
			result["entities"] = enemies.filter(func(enemy): return caster.global_position.distance_to(enemy.global_position) <= spec.range)
			result["positions"] = result["entities"].map(func(enemy): return enemy.global_position)
		TargetSpec.Type.STATUS_PRIORITY:
			var matching := enemies.filter(func(enemy): return enemy.status and enemy.status.has_status(spec.priority_status))
			var selected: EntityBase = matching[0] if not matching.is_empty() else enemies[0] if not enemies.is_empty() else null
			if selected:
				result["entities"] = [selected]
				result["positions"] = [selected.global_position]
		TargetSpec.Type.LOWEST_HP:
			var lowest: EntityBase
			for enemy in enemies:
				if caster.global_position.distance_to(enemy.global_position) <= spec.range and (lowest == null or enemy.stats.hp / maxf(1.0, enemy.stats.max_hp) < lowest.stats.hp / maxf(1.0, lowest.stats.max_hp)):
					lowest = enemy
			if lowest:
				result["entities"] = [lowest]
				result["positions"] = [lowest.global_position]
				result["direction"] = caster.global_position.direction_to(lowest.global_position)
		TargetSpec.Type.ANCHOR_POINT:
			var point := caster.anchor.get_point(spec.anchor_name) if caster.anchor else caster.global_position
			result["positions"] = [point]
			var nearest := _nearest(caster, enemies, spec.range)
			result["direction"] = caster.global_position.direction_to(nearest.global_position) if nearest else Vector2.RIGHT
	if spec.cancel_if_no_target and result["entities"].is_empty() and result["positions"].is_empty():
		return {}
	return result


func _living_enemies() -> Array[EntityBase]:
	var result: Array[EntityBase] = []
	if _scene_tree == null:
		return result
	for node in _scene_tree.get_nodes_in_group(&"enemy") + _scene_tree.get_nodes_in_group(&"boss"):
		var enemy := node as EntityBase
		if enemy and enemy.is_alive() and not result.has(enemy):
			result.append(enemy)
	return result



func _densest(enemies: Array[EntityBase], radius: float) -> EntityBase:
	if enemies.is_empty():
		return null
	var best: EntityBase = enemies[0]
	var best_count := -1
	for candidate in enemies:
		var count := 0
		for other in enemies:
			if candidate.global_position.distance_to(other.global_position) <= radius:
				count += 1
		if count > best_count:
			best = candidate
			best_count = count
	return best

func _nearest(caster: EntityBase, enemies: Array[EntityBase], range_limit: float) -> EntityBase:
	var nearest: EntityBase
	var best := range_limit * range_limit
	for enemy in enemies:
		var distance := caster.global_position.distance_squared_to(enemy.global_position)
		if distance <= best:
			best = distance
			nearest = enemy
	return nearest

