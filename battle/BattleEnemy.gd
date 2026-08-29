extends CharacterBody2D
class_name BattleEnemy

signal defeated(enemy: BattleEnemy)

enum AttackState { CHASE, TELEGRAPH, RECOVER }

var role: EnemyDef.Role = EnemyDef.Role.MELEE
var target: BattlePlayer
var arena: BattleArena
var enemy_id: StringName = &""
var display_name := ""
var max_hp := 30.0
var hp := 30.0
var speed := 95.0
var touch_damage := 7.0
var attack_cooldown := 1.0
var special_cooldown := 4.0
var is_boss := false
var is_named := false
var state := AttackState.CHASE
var state_time := 0.0
var pattern_index := 0
var aim_direction := Vector2.RIGHT
var anim_time := 0.0
var hit_flash := 0.0
var impulse_velocity := Vector2.ZERO
var statuses: Dictionary = {}
var reaction_cooldown := 0.0
var defense_break_left := 0.0
var stun_left := 0.0

func setup(enemy_role: EnemyDef.Role, player: BattlePlayer, owner_arena: BattleArena, difficulty_scale: float = 1.0, boss := false, definition: EnemyDef = null) -> void:
	role = enemy_role
	target = player
	arena = owner_arena
	is_boss = boss or (definition != null and definition.rank == EnemyDef.Rank.BOSS)
	is_named = definition != null and definition.rank == EnemyDef.Rank.NAMED
	if definition:
		enemy_id = definition.id
		display_name = definition.display_name
		role = definition.role
		max_hp = definition.base_max_hp * difficulty_scale * (1.8 if is_named else 1.0)
		speed = definition.base_move_speed
		touch_damage = definition.base_attack_power * difficulty_scale
	else:
		enemy_id = StringName("role_%d" % role)
		display_name = _role_name()
		max_hp = (420.0 if is_boss else 32.0 + role * 8.0) * difficulty_scale
		speed = 70.0 if is_boss else 82.0 + role * 3.0
		touch_damage = (14.0 if is_boss else 6.0 + role * 0.7) * difficulty_scale
	hp = max_hp
	attack_cooldown = 1.0 + role * 0.12

func _ready() -> void:
	add_to_group(&"battle_enemy")

func body_radius() -> float:
	return 38.0 if is_boss else 23.0 if is_named else 17.0

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or hp <= 0.0:
		return
	anim_time += delta
	hit_flash = maxf(0.0, hit_flash - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	special_cooldown = maxf(0.0, special_cooldown - delta)
	reaction_cooldown = maxf(0.0, reaction_cooldown - delta)
	defense_break_left = maxf(0.0, defense_break_left - delta)
	stun_left = maxf(0.0, stun_left - delta)
	state_time = maxf(0.0, state_time - delta)
	_update_statuses(delta)
	if stun_left > 0.0:
		velocity = impulse_velocity
		impulse_velocity = impulse_velocity.move_toward(Vector2.ZERO, 800.0 * delta)
		move_and_slide()
		queue_redraw()
		return
	var to_player := target.global_position - global_position
	if to_player != Vector2.ZERO:
		aim_direction = to_player.normalized()
	if state == AttackState.TELEGRAPH:
		velocity = Vector2.ZERO
		if state_time <= 0.0:
			_perform_attack()
	elif state == AttackState.RECOVER:
		velocity = Vector2.ZERO
		if state_time <= 0.0:
			state = AttackState.CHASE
	else:
		_update_chase(to_player)
		if attack_cooldown <= 0.0 and _ready_to_attack(to_player.length()):
			state = AttackState.TELEGRAPH
			state_time = 0.78 if is_boss or is_named else 0.62
			velocity = Vector2.ZERO
	impulse_velocity = impulse_velocity.move_toward(Vector2.ZERO, 720.0 * delta)
	velocity += impulse_velocity
	move_and_slide()
	queue_redraw()

func _update_chase(to_player: Vector2) -> void:
	var distance := to_player.length()
	match role:
		EnemyDef.Role.RANGED, EnemyDef.Role.SUPPORT, EnemyDef.Role.SUMMONER, EnemyDef.Role.DISRUPTOR:
			if distance < 250.0:
				velocity = -aim_direction * speed
			elif distance > 390.0:
				velocity = aim_direction * speed
			else:
				velocity = aim_direction.rotated(PI * 0.5) * speed * 0.55
		EnemyDef.Role.CHARGER:
			velocity = aim_direction * speed * 1.12
		EnemyDef.Role.BOMBER:
			velocity = aim_direction * speed * 0.92
		_:
			velocity = aim_direction * speed

func _ready_to_attack(distance: float) -> bool:
	match role:
		EnemyDef.Role.RANGED, EnemyDef.Role.SUPPORT, EnemyDef.Role.SUMMONER, EnemyDef.Role.DISRUPTOR:
			return distance <= 470.0
		EnemyDef.Role.CHARGER:
			return distance <= 430.0
		EnemyDef.Role.BOMBER:
			return distance <= 115.0
		_:
			return distance <= (175.0 if is_boss else 118.0)

func _perform_attack() -> void:
	pattern_index += 1
	if is_named:
		match enemy_id:
			&"red_supervisor":
				_shield_bash() if pattern_index % 2 == 0 else _summon_wave()
			&"lady_of_pressure":
				_charge_attack() if pattern_index % 2 == 0 else _ranged_fan()
			&"void_welder":
				_disruptor_zone() if pattern_index % 2 == 0 else _void_shift()
			_:
				_melee_sweep()
	elif is_boss and pattern_index % 3 == 0:
		_boss_radial_burst(14, anim_time)
	else:
		match role:
			EnemyDef.Role.MELEE: _melee_sweep()
			EnemyDef.Role.RANGED: _ranged_aimed_burst()
			EnemyDef.Role.SUPPORT: _support_pulse()
			EnemyDef.Role.SUMMONER: _summon_wave()
			EnemyDef.Role.DISRUPTOR: _disruptor_zone()
			EnemyDef.Role.CHARGER: _charge_attack()
			EnemyDef.Role.BOMBER: _self_destruct()
			EnemyDef.Role.SHIELD: _shield_bash()
	state = AttackState.RECOVER
	state_time = 0.42
	attack_cooldown = 1.25 if is_boss else 1.65 + role * 0.10

func _melee_sweep() -> void:
	arena.spawn_hostile_vfx(CombatVfx.Kind.SLASH, global_position, ArtDirection.MAGENTA, 120.0 if not is_boss else 165.0, 0.35, aim_direction, 115.0)
	if global_position.distance_to(target.global_position) <= (130.0 if not is_boss else 175.0):
		target.take_hit(touch_damage)

func _ranged_fan() -> void:
	for offset in [-0.30, -0.15, 0.0, 0.15, 0.30]:
		arena.spawn_enemy_projectile(global_position, aim_direction.rotated(offset), touch_damage * 0.75, _role_color(), 330.0)

func _ranged_aimed_burst() -> void:
	for index in range(3):
		arena.spawn_delayed_enemy_projectile(global_position, aim_direction, touch_damage * 0.65, _role_color(), 470.0, index * 0.13)

func _support_pulse() -> void:
	arena.heal_nearby_enemies(global_position, 230.0, 18.0)
	arena.spawn_hostile_vfx(CombatVfx.Kind.HEAL, global_position, _role_color(), 230.0, 0.7)

func _summon_wave() -> void:
	arena.spawn_hostile_vfx(CombatVfx.Kind.RING, global_position, _role_color(), 120.0, 0.7)
	for index in range(2 if not is_boss else 3):
		arena.spawn_enemy(EnemyDef.Role.MELEE if index % 2 == 0 else EnemyDef.Role.RANGED)

func _disruptor_zone() -> void:
	arena.spawn_hostile_zone(target.global_position, 105.0, touch_damage * 0.45, 3.2)

func _charge_attack() -> void:
	arena.spawn_hostile_vfx(CombatVfx.Kind.SLASH, global_position + aim_direction * 100.0, ArtDirection.DANGER, 180.0, 0.45, aim_direction, 42.0)
	global_position += aim_direction * 210.0
	if global_position.distance_to(target.global_position) <= 95.0:
		target.take_hit(touch_damage * 1.5)

func _self_destruct() -> void:
	arena.spawn_hostile_vfx(CombatVfx.Kind.IMPACT, global_position, ArtDirection.DANGER, 135.0, 0.6)
	if global_position.distance_to(target.global_position) <= 125.0:
		target.take_hit(touch_damage * 1.8)
	_apply_raw_damage(max_hp * 2.0)

func _shield_bash() -> void:
	arena.spawn_hostile_vfx(CombatVfx.Kind.SLASH, global_position, ArtDirection.YELLOW, 125.0, 0.35, aim_direction, 80.0)
	if global_position.distance_to(target.global_position) <= 125.0:
		target.take_hit(touch_damage * 1.15)


func _void_shift() -> void:
	var side := -1.0 if pattern_index % 4 == 1 else 1.0
	var destination := target.global_position + aim_direction.rotated(side * PI * 0.5) * 240.0
	global_position = Vector2(
		clampf(destination.x, arena.WORLD_RECT.position.x + 80.0, arena.WORLD_RECT.end.x - 80.0),
		clampf(destination.y, arena.WORLD_RECT.position.y + 80.0, arena.WORLD_RECT.end.y - 80.0)
	)
	arena.spawn_hostile_vfx(CombatVfx.Kind.RING, global_position, ArtDirection.VIOLET, 90.0, 0.45)
	arena.spawn_hostile_zone(target.global_position, 92.0, touch_damage * 0.38, 2.8)

func _boss_radial_burst(count: int, angle_offset := 0.0) -> void:
	arena.spawn_hostile_vfx(CombatVfx.Kind.RING, global_position, ArtDirection.DANGER, 190.0, 0.6)
	for index in range(count):
		arena.spawn_enemy_projectile(global_position, Vector2.from_angle(float(index) / count * TAU + angle_offset), touch_damage * 0.65, ArtDirection.DANGER, 285.0)

func take_damage(amount: float, context: Dictionary = {}) -> void:
	if hp <= 0.0:
		return
	var adjusted := amount
	if context.get("family_id", &"") == &"sword" and int(context.get("family_tier", 0)) >= 3 and hp / maxf(1.0, max_hp) <= 0.30:
		adjusted *= 1.25
	if defense_break_left > 0.0 or has_status(&"weakened"):
		adjusted *= 1.15
	if role == EnemyDef.Role.SHIELD and defense_break_left <= 0.0:
		var source: Vector2 = context.get("origin", global_position - aim_direction)
		var incoming := global_position.direction_to(source)
		if incoming.dot(aim_direction) > 0.25:
			adjusted *= 0.36
	if context.get("special_rule", &"") == &"execute" and hp / maxf(1.0, max_hp) <= 0.30:
		adjusted *= 1.55
	if context.get("special_rule", &"") == &"boss_hunter" and (is_boss or is_named):
		adjusted *= 1.8
	if context.get("special_rule", &"") == &"poison_scaling":
		adjusted *= 1.0 + status_stacks(&"poisoned") * 0.18
	if context.get("special_rule", &"") == &"poison_detonate":
		var consumed := status_stacks(&"poisoned")
		adjusted *= 1.0 + consumed * 0.22
		statuses.erase(&"poisoned")
	_apply_raw_damage(adjusted)
	if hp <= 0.0:
		return
	var force := float(context.get("knockback", 0.0))
	if force != 0.0:
		var source: Vector2 = context.get("origin", global_position)
		var direction := source.direction_to(global_position)
		if force < 0.0:
			direction = -direction
		apply_impulse(direction * absf(force))
	var status_id := StringName(context.get("status_id", &""))
	if status_id != &"":
		apply_status(status_id, int(context.get("status_stacks", 1)), float(context.get("status_duration", 4.0)), float(context.get("source_power", adjusted)))
	_check_reactions(float(context.get("source_power", adjusted)))

func _apply_raw_damage(amount: float) -> void:
	hp = maxf(0.0, hp - maxf(0.0, amount))
	hit_flash = 0.1
	if is_instance_valid(arena):
		arena.impact(global_position, _role_color(), 32.0)
	if hp <= 0.0:
		_die()

func _die() -> void:
	if hp > 0.0:
		hp = 0.0
	if is_instance_valid(arena):
		arena.on_enemy_status_death(self)
		arena.spawn_vfx(CombatVfx.Kind.IMPACT, global_position, _role_color(), 90.0 if is_boss else 50.0, 0.55)
	defeated.emit(self)
	queue_free()

func heal(amount: float) -> void:
	hp = minf(max_hp, hp + amount)

func apply_impulse(force: Vector2) -> void:
	impulse_velocity += force

func apply_status(status_id: StringName, stacks: int, duration: float, source_power: float) -> void:
	if status_id == &"stunned":
		stun_left = maxf(stun_left, duration)
		return
	if status_id == &"weakened":
		defense_break_left = maxf(defense_break_left, duration)
	var cap := 99
	match status_id:
		&"burning": cap = int(arena.status_caps.get(&"burning", 5))
		&"poisoned": cap = int(arena.status_caps.get(&"poisoned", 8))
		&"wet": cap = 1
		&"shocked": cap = 3
	var current: Dictionary = statuses.get(status_id, {"stacks": 0, "remaining": 0.0, "power": source_power, "tick": _status_interval(status_id)})
	current["stacks"] = mini(cap, int(current["stacks"]) + maxi(1, stacks))
	current["remaining"] = maxf(float(current["remaining"]), duration)
	current["power"] = maxf(float(current["power"]), source_power)
	statuses[status_id] = current
	queue_redraw()

func has_status(status_id: StringName) -> bool:
	return statuses.has(status_id) and int((statuses[status_id] as Dictionary).get("stacks", 0)) > 0

func status_stacks(status_id: StringName) -> int:
	return int((statuses.get(status_id, {}) as Dictionary).get("stacks", 0))

func consume_status(status_id: StringName, amount: int) -> void:
	if not statuses.has(status_id):
		return
	var state_data: Dictionary = statuses[status_id]
	state_data["stacks"] = maxi(0, int(state_data["stacks"]) - amount)
	if int(state_data["stacks"]) <= 0:
		statuses.erase(status_id)
	else:
		statuses[status_id] = state_data

func _update_statuses(delta: float) -> void:
	var expired: Array[StringName] = []
	for key in statuses.keys():
		var status_id := StringName(key)
		var data: Dictionary = statuses[status_id]
		data["remaining"] = float(data["remaining"]) - delta
		data["tick"] = float(data["tick"]) - delta
		if float(data["tick"]) <= 0.0:
			data["tick"] = _status_interval(status_id)
			var ratio := 0.0
			match status_id:
				&"burning": ratio = 0.04
				&"poisoned": ratio = 0.025
				&"shocked": ratio = 0.05
			if ratio > 0.0:
				_apply_raw_damage(float(data["power"]) * ratio * int(data["stacks"]))
				if hp <= 0.0:
					return
		if float(data["remaining"]) <= 0.0:
			expired.append(status_id)
		else:
			statuses[status_id] = data
	for status_id in expired:
		statuses.erase(status_id)

func _status_interval(status_id: StringName) -> float:
	return 0.35 if status_id == &"shocked" else 0.5

func _check_reactions(source_power: float) -> void:
	if reaction_cooldown > 0.0 or not is_instance_valid(arena):
		return
	if has_status(&"wet") and has_status(&"burning"):
		consume_status(&"wet", 1)
		consume_status(&"burning", 1)
		reaction_cooldown = 0.35
		arena.trigger_reaction(&"steam_burst", self, source_power * 0.45)
	elif has_status(&"wet") and has_status(&"poisoned"):
		consume_status(&"wet", 1)
		reaction_cooldown = 0.35
		arena.trigger_reaction(&"contamination", self, source_power)
	elif has_status(&"burning") and has_status(&"poisoned"):
		consume_status(&"burning", 1)
		consume_status(&"poisoned", 1)
		reaction_cooldown = 0.35
		arena.trigger_reaction(&"toxic_ignite", self, source_power * 0.70)
	elif has_status(&"wet") and has_status(&"shocked"):
		consume_status(&"wet", 1)
		reaction_cooldown = 0.35
		arena.trigger_reaction(&"chain_shock", self, source_power * 0.55)

func _role_name() -> String:
	return ["용광로 사냥개", "리벳 사수", "수리 드론", "주조 배양기", "슬래그 주술사", "압연 돌격기", "보일러 벌레", "철갑 방벽"][role]

func _role_color() -> Color:
	return [ArtDirection.MAGENTA, ArtDirection.YELLOW, ArtDirection.CYAN, ArtDirection.VIOLET, ArtDirection.PINK, ArtDirection.DANGER, ArtDirection.YELLOW, ArtDirection.PAPER_DIM][role]

func _draw() -> void:
	var color := ArtDirection.PAPER if hit_flash > 0.0 else ArtDirection.DANGER if is_boss else _role_color()
	var radius := body_radius()
	var bob := sin(anim_time * 5.0) * 2.0
	var center := Vector2(0, bob)
	draw_circle(center + Vector2(4, 4), radius * 1.20, Color(ArtDirection.CYAN.r, ArtDirection.CYAN.g, ArtDirection.CYAN.b, 0.22))
	var points := PackedVector2Array()
	match role:
		EnemyDef.Role.RANGED:
			points = PackedVector2Array([Vector2(0, -radius * 1.18), Vector2(radius, 0), Vector2(0, radius * 1.18), Vector2(-radius, 0)])
		EnemyDef.Role.SUMMONER, EnemyDef.Role.BOMBER:
			points = PackedVector2Array([Vector2(0, -radius * 1.28), Vector2(radius * 1.05, radius), Vector2(-radius * 1.05, radius)])
		EnemyDef.Role.SHIELD:
			points = PackedVector2Array([Vector2(-radius, radius), Vector2(-radius, -radius), Vector2(radius * 0.3, -radius * 1.2), Vector2(radius, -radius), Vector2(radius, radius)])
		_:
			points = PackedVector2Array([Vector2(-radius, radius), Vector2(-radius * 0.78, -radius), Vector2(0, -radius * 0.64), Vector2(radius * 0.86, -radius), Vector2(radius, radius)])
	_draw_cutout(points, center, color)
	draw_circle(center + Vector2(-radius * 0.24, -radius * 0.08), maxf(2.0, radius * 0.12), ArtDirection.PAPER)
	draw_line(center + Vector2(radius * 0.08, -radius * 0.15), center + Vector2(radius * 0.38, radius * 0.05), ArtDirection.PAPER, 3.0)
	if state == AttackState.TELEGRAPH:
		var telegraph_total := 0.78 if is_boss or is_named else 0.62
		draw_arc(center, radius + 9.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - state_time / telegraph_total), 14, ArtDirection.DANGER, 5.0, false)
	var status_index := 0
	for status_id in statuses.keys():
		draw_circle(center + Vector2(-radius + status_index * 9, radius + 9), 4.0, _status_color(StringName(status_id)))
		status_index += 1
	var hp_rect := Rect2(-radius, bob - radius - 14.0, radius * 2.0, 6.0)
	draw_rect(Rect2(hp_rect.position + Vector2(3, 3), hp_rect.size), ArtDirection.CYAN)
	draw_rect(hp_rect, ArtDirection.VOID)
	draw_rect(Rect2(hp_rect.position + Vector2(1, 1), Vector2((hp_rect.size.x - 2.0) * hp / max_hp, hp_rect.size.y - 2.0)), ArtDirection.MAGENTA if not is_boss else ArtDirection.YELLOW)

func _status_color(status_id: StringName) -> Color:
	match status_id:
		&"burning": return Color("ff6b35")
		&"poisoned": return Color("90d934")
		&"wet": return Color("35c8ff")
		&"shocked": return ArtDirection.YELLOW
		_: return ArtDirection.PAPER

func _draw_cutout(points: PackedVector2Array, offset: Vector2, color: Color) -> void:
	var shadow := PackedVector2Array()
	var outline := PackedVector2Array()
	var inner := PackedVector2Array()
	for point in points:
		shadow.append(point + offset + Vector2(5, 5))
		outline.append(point + offset)
		inner.append(point * 0.76 + offset)
	draw_colored_polygon(shadow, ArtDirection.CYAN)
	draw_colored_polygon(outline, ArtDirection.VOID)
	draw_colored_polygon(inner, color)