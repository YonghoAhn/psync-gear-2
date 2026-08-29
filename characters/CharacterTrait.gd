extends Resource
class_name CharacterTrait

enum Type { CARD_FAMILY, STAT, RELIC_OR_NODE, SPECIAL_RULE }

@export var id: StringName = &""
@export var type: Type = Type.STAT
@export_multiline var description := ""
@export var stat_modifiers: Array[Dictionary] = []
@export var family_id: StringName = &""
@export var family_weight_multiplier := 1.0
@export var event_hooks: Array[StringName] = []
@export var rule_values: Dictionary = {}


func apply_stats(stats: CombatStatsComponent) -> void:
	for modifier in stat_modifiers:
		stats.add_modifier(id, StringName(modifier.get("stat", "")), modifier.get("type", "flat"), float(modifier.get("value", 0.0)))


func handles(event_name: StringName) -> bool:
	return event_hooks.has(event_name)

