extends RefCounted
class_name BattleCardExecutor

var arena: BattleArena
var resolver: BattleTargetResolver


func setup(owner_arena: BattleArena, target_resolver: BattleTargetResolver) -> void:
	arena = owner_arena
	resolver = target_resolver


func build_context(card: CardInstance) -> Dictionary:
	var card_def := card.card_def
	var origin := arena.player.global_position
	var target_data := resolver.resolve(card_def, origin)
	var spec: EffectSpec = card_def.effect_specs[0] as EffectSpec if not card_def.effect_specs.is_empty() else null
	var power := (spec.power if spec else card_def.base_power) + card.upgrade_level * 4.0
	var tier := int(arena.family_tiers.get(card_def.family_id, 0))
	if card_def.family_id == &"sword" and tier >= 1:
		power *= 1.10
	if arena.survivor_mode:
		power *= arena.survivor_power_multiplier
	var aim: Vector2 = target_data["aim"]
	if not (target_data["targets"] as Array).is_empty():
		arena.player.facing_direction = aim
	var effect_point: Vector2 = target_data["effect_point"]
	if card_def.target_priority == CardDef.TargetPriority.SELF:
		effect_point = origin
	var target_points: Array[Vector2] = []
	for enemy in target_data["targets"]:
		target_points.append((enemy as BattleEnemy).global_position)
	return {
		"origin": origin,
		"aim": aim,
		"effect_point": effect_point,
		"target_points": target_points,
		"power": power,
		"color": ArtDirection.family_color(card_def.family_id),
		"family_tier": tier,
		"has_target": not (target_data["targets"] as Array).is_empty() or card_def.target_priority == CardDef.TargetPriority.SELF,
	}


func resolve(card: CardInstance, context: Dictionary) -> void:
	var card_def := card.card_def
	if card_def == null or arena.ended:
		return
	var origin: Vector2 = context["origin"]
	var aim: Vector2 = context["aim"]
	var effect_point: Vector2 = context["effect_point"]
	var power: float = context["power"]
	var color: Color = context["color"]
	var tier := int(context.get("family_tier", 0))
	var hit_context := _hit_context(card_def, origin, power, tier)
	match card_def.attack_pattern:
		CardDef.AttackPattern.MELEE_ARC:
			arena.spawn_vfx(CombatVfx.Kind.SLASH, origin, color, card_def.max_range, 0.38, aim, card_def.arc_degrees)
			for enemy in arena.enemies_in_range_from(origin, _effective_range(card_def, tier)):
				if absf(aim.angle_to((enemy.global_position - origin).normalized())) <= deg_to_rad(card_def.arc_degrees * 0.5):
					_hit_repeated(enemy, power, card_def.hit_count, hit_context)
			arena.shake(4.0, 0.12)
		CardDef.AttackPattern.THRUST:
			var attack_range := _effective_range(card_def, tier)
			arena.spawn_vfx(CombatVfx.Kind.SLASH, origin + aim * attack_range * 0.5, color, attack_range * 0.55, 0.35, aim, 20.0)
			for enemy in arena.enemies_in_range_from(origin, attack_range):
				var offset := enemy.global_position - origin
				var along := offset.dot(aim)
				var perpendicular := absf(offset.cross(aim))
				if along >= 0.0 and along <= attack_range and perpendicular <= maxf(18.0, card_def.impact_radius):
					_hit_repeated(enemy, power * 1.15, card_def.hit_count, hit_context)
			arena.shake(5.0, 0.13)
		CardDef.AttackPattern.PROJECTILE:
			_spawn_projectiles(card_def, origin, aim, context.get("target_points", []), power, color, hit_context, tier)
		CardDef.AttackPattern.NOVA:
			_resolve_nova(card_def, effect_point, power, color, hit_context, tier)
		CardDef.AttackPattern.ZONE:
			var duration := 3.5 * (1.28 if card_def.family_id == &"water" and tier >= 2 else 1.0)
			var radius := card_def.impact_radius * (1.18 if card_def.family_id == &"water" and tier >= 2 else 1.0)
			var zone_context := hit_context.duplicate(true)
			if card_def.special_rule in [&"pull_zone", &"slow_zone"]:
				zone_context["pull_force"] = card_def.knockback_force
			arena.spawn_friendly_zone(effect_point, radius, power * 0.32, duration, color, zone_context, card.instance_id, maxi(2, card_def.active_limit))
		CardDef.AttackPattern.DEFENSE:
			_resolve_defense(card, context, hit_context)
		CardDef.AttackPattern.MOVEMENT:
			arena.player.try_dodge()


func _hit_context(card_def: CardDef, origin: Vector2, power: float, tier: int) -> Dictionary:
	var spec: EffectSpec = card_def.effect_specs[0] as EffectSpec if not card_def.effect_specs.is_empty() else null
	var stacks := spec.status_stacks if spec else card_def.status_stacks
	var duration := spec.duration if spec else card_def.status_duration
	if card_def.family_id in [&"fire", &"poison"] and tier >= 1 and stacks > 0:
		stacks += 1
	if card_def.family_id == &"water" and tier >= 1 and duration > 0.0:
		duration += 2.0
	var status_id := spec.status_id if spec else card_def.status_id
	if status_id == &"" and arena.flaming_weapon_left > 0.0 and card_def.family_id in [&"sword", &"spear", &"blunt"]:
		status_id = &"burning"
		stacks = 1
		duration = 4.0
	var result := {
		"origin": origin,
		"source_power": power,
		"family_id": card_def.family_id,
		"family_tier": tier,
		"status_id": status_id,
		"status_stacks": stacks,
		"status_duration": duration,
		"knockback": (spec.knockback_force if spec else card_def.knockback_force) * (1.30 if card_def.family_id == &"blunt" and tier >= 1 else 1.0),
		"special_rule": card_def.special_rule,
		"projectile_aoe": card_def.special_rule == &"projectile_aoe",
		"impact_radius": card_def.impact_radius,
	}
	if card_def.family_id == &"spear" and tier >= 3 and card_def.attack_pattern == CardDef.AttackPattern.THRUST:
		result["status_id"] = &"weakened"
		result["status_stacks"] = 1
		result["status_duration"] = maxf(3.0, duration)
	if card_def.family_id == &"blunt" and tier >= 3 and card_def.execution_interval >= 1.2:
		result["status_id"] = &"stunned"
		result["status_stacks"] = 1
		result["status_duration"] = 0.25
	return result


func _hit_repeated(enemy: BattleEnemy, power: float, count: int, hit_context: Dictionary) -> void:
	var hits := maxi(1, count)
	var per_hit := power if hits == 1 else power * 0.62
	for _index in range(hits):
		if is_instance_valid(enemy):
			enemy.take_damage(per_hit, hit_context)


func _effective_range(card_def: CardDef, tier: int) -> float:
	return card_def.max_range * (1.15 if card_def.family_id == &"spear" and tier >= 1 else 1.0)


func _spawn_projectiles(card_def: CardDef, origin: Vector2, aim: Vector2, target_points: Array, power: float, color: Color, hit_context: Dictionary, tier: int) -> void:
	var count := maxi(1, card_def.projectile_count)
	var pierce := card_def.pierce_count + (1 if card_def.family_id == &"spear" and tier >= 2 else 0)
	for index in range(count):
		var direction := aim
		if index < target_points.size():
			direction = origin.direction_to(target_points[index])
		elif count > 1:
			direction = aim.rotated(lerpf(-0.22, 0.22, float(index) / maxf(1.0, count - 1.0)))
		arena.spawn_player_projectile(origin + direction * 24.0, direction, power, color, card_def.projectile_speed, maxf(6.0, card_def.impact_radius * 0.24), hit_context, pierce, _effective_range(card_def, tier))


func _resolve_nova(card_def: CardDef, effect_point: Vector2, power: float, color: Color, hit_context: Dictionary, tier: int) -> void:
	var effect_radius := maxf(48.0, card_def.impact_radius)
	if card_def.family_id == &"blunt" and tier >= 2:
		effect_radius *= 1.18
	var is_meteor := card_def.id == &"meteor_strike"
	if is_meteor:
		arena.spawn_vfx(CombatVfx.Kind.RING, effect_point, ArtDirection.CYAN, effect_radius * 1.45, 1.20)
		arena.spawn_vfx(CombatVfx.Kind.IMPACT, effect_point, ArtDirection.YELLOW, effect_radius * 1.15, 1.00)
		arena.spawn_vfx(CombatVfx.Kind.RING, effect_point, ArtDirection.YELLOW, effect_radius * 0.78, 0.85)
	else:
		arena.spawn_vfx(CombatVfx.Kind.RING, effect_point, color, effect_radius, 0.62)
		arena.spawn_vfx(CombatVfx.Kind.IMPACT, effect_point, color, effect_radius * 0.72, 0.48)
	for enemy in arena.enemies_in_range_from(effect_point, effect_radius):
		enemy.take_damage(power * (1.0 if is_meteor else 0.85), hit_context)
	if card_def.special_rule == &"poison_detonate" and tier >= 3:
		var zone_context := hit_context.duplicate(true)
		zone_context["status_id"] = &"poisoned"
		zone_context["status_stacks"] = 1
		arena.spawn_friendly_zone(effect_point, 105.0, power * 0.18, 3.2, color, zone_context, &"poison_detonate_zone", 2)
	arena.shake(24.0, 1.0) if is_meteor else arena.shake(9.0 if card_def.execution_interval >= 2.5 else 7.0, 0.22)


func _resolve_defense(card: CardInstance, context: Dictionary, hit_context: Dictionary) -> void:
	var card_def := card.card_def
	if card_def.summon_kind != &"":
		arena.spawn_card_construct(card, context["effect_point"], context["power"], context["color"], hit_context)
		return
	match card_def.special_rule:
		&"flaming_weapon":
			arena.flaming_weapon_left = maxf(arena.flaming_weapon_left, 7.0)
		&"heat_guard":
			arena.player.grant_shield(16.0 + card.upgrade_level * 3.0)
			arena.damage_area(arena.player.global_position, maxf(110.0, card_def.impact_radius), context["power"] * 0.55, hit_context)
		&"sword_stance":
			arena.player.grant_shield(18.0 + card.upgrade_level * 3.0)
		_:
			arena.player.grant_shield(15.0 + card.upgrade_level * 3.0)
