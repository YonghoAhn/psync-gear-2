extends Resource
class_name BossPhaseDef

@export var id: StringName = &""
@export_range(0.0, 1.0) var starts_at_health_ratio := 1.0
@export var patterns: Array[Resource] = []
@export var stat_modifiers: Array[Dictionary] = []

