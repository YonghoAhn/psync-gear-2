extends Node2D
class_name BattleHazard

var arena: BattleArena
var radius := 100.0
var damage := 5.0
var lifetime := 3.0
var tick := 0.35
var tick_interval := 0.45
var hostile := true
var tint := ArtDirection.MAGENTA
var hit_context: Dictionary = {}

func setup(owner_arena: BattleArena, at: Vector2, size: float, power: float, seconds: float, enemy_zone := true, color := ArtDirection.MAGENTA, context: Dictionary = {}) -> void:
	arena = owner_arena
	global_position = at
	radius = size
	damage = power
	lifetime = seconds
	hostile = enemy_zone
	tint = color
	hit_context = context.duplicate(true)
	add_to_group(&"battle_card_spawn") if not hostile else add_to_group(&"battle_hostile_hazard")

func _process(delta: float) -> void:
	lifetime -= delta
	tick -= delta
	if tick <= 0.0:
		tick = tick_interval
		if hostile and is_instance_valid(arena.player) and global_position.distance_to(arena.player.global_position) <= radius:
			arena.player.take_hit(damage)
		elif not hostile:
			for node in get_tree().get_nodes_in_group(&"battle_enemy"):
				var enemy := node as BattleEnemy
				if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) <= radius:
					enemy.take_damage(damage, hit_context)
					if float(hit_context.get("pull_force", 0.0)) != 0.0:
						enemy.apply_impulse(enemy.global_position.direction_to(global_position) * absf(float(hit_context["pull_force"])))
	queue_redraw()
	if lifetime <= 0.0:
		queue_free()

func _draw() -> void:
	var pulse := 0.76 + sin(Time.get_ticks_msec() * 0.014) * 0.10
	var primary := ArtDirection.DANGER if hostile else ArtDirection.CYAN
	var registration := ArtDirection.MAGENTA if hostile else ArtDirection.PAPER
	var accent := ArtDirection.MAGENTA if hostile else ArtDirection.YELLOW
	for y in range(-5, 6):
		for x in range(-5, 6):
			var p := Vector2(x, y) * radius * 0.16
			if p.length() < radius * 0.88 and (x + y) % 2 == 0:
				draw_circle(p + Vector2(3, 3), 3.5, Color(registration.r, registration.g, registration.b, 0.24))
				draw_circle(p, 3.0, Color(primary.r, primary.g, primary.b, 0.42))
	var ring := PackedVector2Array()
	for i in range(29):
		var a := float(i) / 28.0 * TAU
		var jag := radius * pulse * (1.0 + (0.035 if i % 2 else -0.035))
		ring.append(Vector2.from_angle(a) * jag)
	ring.append(ring[0])
	var shadow := PackedVector2Array()
	for point in ring:
		shadow.append(point + Vector2(5, 5))
	draw_polyline(shadow, Color(registration.r, registration.g, registration.b, 0.68), 7.0, false)
	draw_polyline(ring, ArtDirection.VOID, 10.0, false)
	draw_polyline(ring, Color(primary.r, primary.g, primary.b, 0.95), 5.0, false)
	for i in range(9):
		var p := Vector2.from_angle(float(i) / 9.0 * TAU + lifetime) * radius * 0.72
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -5), p + Vector2(5, 4), p + Vector2(-5, 4)]), accent)