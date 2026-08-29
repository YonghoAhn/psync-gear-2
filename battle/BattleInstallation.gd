extends Node2D
class_name BattleInstallation

var arena: BattleArena
var source_id: StringName
var kind: StringName
var power := 8.0
var radius := 160.0
var lifetime := 9.0
var cooldown := 0.25
var tint := ArtDirection.CYAN
var hit_context: Dictionary = {}


func setup(owner_arena: BattleArena, card_id: StringName, installation_kind: StringName, at: Vector2, attack_power: float, attack_radius: float, color: Color, context: Dictionary) -> void:
	arena = owner_arena
	source_id = card_id
	kind = installation_kind
	global_position = at
	power = attack_power
	radius = attack_radius
	tint = color
	hit_context = context.duplicate(true)
	add_to_group(&"battle_card_spawn")
	queue_redraw()


func _process(delta: float) -> void:
	lifetime -= delta
	cooldown -= delta
	if cooldown <= 0.0 and is_instance_valid(arena) and not arena.ended:
		cooldown = 0.72 if kind != &"flower" else 0.95
		var targets := arena.enemies_in_range_from(global_position, radius)
		if kind == &"formation":
			arena.player.grant_shield(2.0)
		if not targets.is_empty():
			targets.sort_custom(func(a: BattleEnemy, b: BattleEnemy): return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position))
			var target := targets[0]
			if kind == &"flower":
				for enemy in targets:
					enemy.take_damage(power * 0.38, hit_context)
			else:
				var direction := (target.global_position - global_position).normalized()
				arena.spawn_player_projectile(global_position, direction, power * 0.55, tint, 560.0, 7.0, hit_context, 0, radius)
	queue_redraw()
	if lifetime <= 0.0:
		queue_free()


func _draw() -> void:
	var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.009) * 0.08
	draw_circle(Vector2(4, 4), 24.0 * pulse, ArtDirection.VOID)
	draw_circle(Vector2.ZERO, 21.0 * pulse, tint)
	draw_rect(Rect2(-11, -11, 22, 22), ArtDirection.PAPER, false, 4.0)
	draw_arc(Vector2.ZERO, radius * 0.22, 0, TAU, 18, Color(tint.r, tint.g, tint.b, 0.42), 3.0)
