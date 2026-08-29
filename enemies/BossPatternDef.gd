extends Resource
class_name BossPatternDef

@export var id: StringName = &""
@export var weight := 1.0
@export var cooldown := 3.0
@export var telegraph_duration := 0.8
@export var action_duration := 0.5
@export var tags: Array[StringName] = []
@export var incompatible_tags: Array[StringName] = []
@export var behavior: EnemyBehaviorDef
@export var failure_condition_id: StringName = &""

