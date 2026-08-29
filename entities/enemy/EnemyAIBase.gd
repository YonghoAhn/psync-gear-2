extends RefCounted
class_name EnemyAIBase

var _def: EnemyDef
var _enemy: Node2D
var _attack_timer := 0.0


func setup(definition: EnemyDef, enemy: Node2D) -> void:
	_def = definition
	_enemy = enemy


func tick(delta: float, target: Node2D) -> Vector2:
	if target == null or _enemy == null:
		return Vector2.ZERO
	_attack_timer = maxf(0.0, _attack_timer - delta)
	var offset := target.global_position - _enemy.global_position
	var distance := offset.length()
	match _def.ai_type:
		EnemyDef.AIType.RANGED:
			if distance < _def.preferred_distance - 20.0:
				return -offset.normalized()
			if distance > _def.preferred_distance + 20.0:
				return offset.normalized()
			return offset.normalized().rotated(PI * 0.5) * 0.3
		EnemyDef.AIType.CIRCLE:
			return offset.normalized().rotated(PI * 0.5)
		_:
			return offset.normalized()


static func create(definition: EnemyDef, enemy: Node2D) -> EnemyAIBase:
	var brain := EnemyAIBase.new()
	brain.setup(definition, enemy)
	return brain

