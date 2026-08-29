extends RefCounted
class_name DamagePipeline

static func calculate(context: DamageContext, defender: CombatStatsComponent) -> float:
	var scaling_stat := 0.0
	if context.attacker_stats != null:
		match context.damage_type:
			DamageContext.Type.MAGITECH:
				scaling_stat = context.attacker_stats.magitech_power
			_:
				scaling_stat = context.attacker_stats.magic_power
	var damage := context.base_damage + scaling_stat * context.stat_coefficient
	if context.critical:
		damage *= maxf(1.0, context.critical_multiplier)
	damage *= maxf(0.0, context.damage_increase)
	if context.damage_type != DamageContext.Type.PURE and defender != null:
		damage *= 100.0 / (100.0 + maxf(0.0, defender.defense))
		damage *= 1.0 - defender.get_resistance(context.damage_type)
	damage *= maxf(0.0, context.difficulty_modifier)
	return maxf(0.0, damage)

