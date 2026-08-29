extends RefCounted
class_name EnemyBrain

var definition: EnemyDef
var _cooldowns: Dictionary = {}


func initialize(enemy_def: EnemyDef) -> void:
	definition = enemy_def
	_cooldowns.clear()


func tick(delta: float, distance_to_player: float, ally_needs_help: bool = false) -> Dictionary:
	for action_id in _cooldowns.keys():
		_cooldowns[action_id] = maxf(0.0, float(_cooldowns[action_id]) - delta)
	var candidates: Array[EnemyBehaviorDef] = []
	for resource in definition.behavior_modules:
		var behavior := resource as EnemyBehaviorDef
		if behavior == null or float(_cooldowns.get(behavior.id, 0.0)) > 0.0:
			continue
		if behavior.action in [EnemyBehaviorDef.Action.HEAL_ALLY, EnemyBehaviorDef.Action.BUFF_ALLY] and not ally_needs_help:
			continue
		if behavior.action not in [EnemyBehaviorDef.Action.CHASE, EnemyBehaviorDef.Action.KEEP_DISTANCE] and distance_to_player > behavior.range:
			continue
		candidates.append(behavior)
	if candidates.is_empty():
		return {"action": EnemyBehaviorDef.Action.CHASE, "power": 0.0}
	candidates.sort_custom(func(left, right): return left.priority > right.priority)
	var selected := candidates[0]
	_cooldowns[selected.id] = selected.cooldown
	return {
		"id": selected.id,
		"action": selected.action,
		"power": selected.power,
		"status_id": selected.status_id,
		"summon_enemy_id": selected.summon_enemy_id,
	}


static func required_role_action(role: EnemyDef.Role) -> EnemyBehaviorDef.Action:
	match role:
		EnemyDef.Role.MELEE: return EnemyBehaviorDef.Action.MELEE_ATTACK
		EnemyDef.Role.RANGED: return EnemyBehaviorDef.Action.PROJECTILE_ATTACK
		EnemyDef.Role.SUPPORT: return EnemyBehaviorDef.Action.HEAL_ALLY
		EnemyDef.Role.SUMMONER: return EnemyBehaviorDef.Action.SUMMON
		EnemyDef.Role.DISRUPTOR: return EnemyBehaviorDef.Action.APPLY_DEBUFF
		EnemyDef.Role.CHARGER: return EnemyBehaviorDef.Action.CHARGE
		EnemyDef.Role.BOMBER, EnemyDef.Role.SHIELD: return EnemyBehaviorDef.Action.MELEE_ATTACK
	return EnemyBehaviorDef.Action.CHASE

