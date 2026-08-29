extends Resource
class_name BossDef

@export var id: StringName = &""
@export var display_name := ""
@export var base_enemy: EnemyDef
@export var phases: Array[Resource] = []


func sorted_phases() -> Array[BossPhaseDef]:
	var result: Array[BossPhaseDef] = []
	for resource in phases:
		var phase := resource as BossPhaseDef
		if phase:
			result.append(phase)
	result.sort_custom(func(left, right): return left.starts_at_health_ratio > right.starts_at_health_ratio)
	return result

