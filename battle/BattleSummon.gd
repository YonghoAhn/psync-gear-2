extends CharacterBody2D
class_name BattleSummon

var arena: BattleArena
var source_id: StringName
var kind: StringName
var power := 12.0
var attack_range := 260.0
var cooldown := 0.2
var lifetime := 12.0
var tint := ArtDirection.CYAN
var hit_context: Dictionary = {}


func setup(owner_arena: BattleArena, card_id: StringName, summon_kind: StringName, at: Vector2, attack_power: float, radius: float, color: Color, context: Dictionary) -> void:
	arena = owner_arena
	source_id = card_id
	kind = summon_kind
	global_position = at
	power = attack_power
	attack_range = maxf(180.0, radius * 3.0)
	tint = color
	hit_context = context.duplicate(true)
	add_to_group(&"battle_card_spawn")


func _physics_process(delta: float) -> void:
	if not is_instance_valid(arena) or arena.ended:
		queue_free()
		return
	lifetime -= delta
	cooldown -= delta
	var targets := arena.enemies_in_range_from(global_position, attack_range)
	if targets.is_empty():
		var follow_point := arena.player.global_position + Vector2(-42, 28)
		velocity = global_position.direction_to(follow_point) * 145.0 if global_position.distance_to(follow_point) > 55.0 else Vector2.ZERO
	else:
		targets.sort_custom(func(a: BattleEnemy, b: BattleEnemy): return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position))
		var target := targets[0]
		var distance := global_position.distance_to(target.global_position)
		velocity = global_position.direction_to(target.global_position) * (125.0 if distance > 75.0 else 0.0)
		if cooldown <= 0.0:
			cooldown = 0.82
			if kind == &"spirit":
				arena.spawn_player_projectile(global_position, global_position.direction_to(target.global_position), power * 0.55, tint, 520.0, 7.0, hit_context, 0, attack_range)
				arena.player.grant_shield(1.5)
			else:
				target.take_damage(power * 0.68, hit_context)
				arena.spawn_vfx(CombatVfx.Kind.IMPACT, target.global_position, tint, 38.0, 0.25)
	move_and_slide()
	queue_redraw()
	if lifetime <= 0.0:
		queue_free()


func _draw() -> void:
	var bob := sin(Time.get_ticks_msec() * 0.008) * 3.0
	draw_circle(Vector2(4, bob + 4), 18, ArtDirection.VOID)
	draw_circle(Vector2(0, bob), 16, tint)
	draw_circle(Vector2(-5, bob - 2), 3, ArtDirection.PAPER)
	draw_line(Vector2(3, bob - 2), Vector2(9, bob - 2), ArtDirection.VOID, 3.0)
