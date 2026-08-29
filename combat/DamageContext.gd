extends RefCounted
class_name DamageContext

enum Type { PHYSICAL, MAGIC, MAGITECH, PURE }

var base_damage := 0.0
var stat_coefficient := 0.0
var damage_type: Type = Type.PHYSICAL
var critical := false
var critical_multiplier := 1.0
var damage_increase := 1.0
var difficulty_modifier := 1.0
var attacker_stats: CombatStatsComponent
var source: Variant
var tags: Array[StringName] = []


static func create(base: float, coefficient: float = 0.0, type: Type = Type.PHYSICAL) -> DamageContext:
	var context := DamageContext.new()
	context.base_damage = base
	context.stat_coefficient = coefficient
	context.damage_type = type
	return context

