extends Node2D
class_name BattleProjectile

var velocity := Vector2.ZERO
var damage := 8.0
var radius := 9.0
var lifetime := 3.0
var hostile := true
var tint := ArtDirection.MAGENTA
var arena: BattleArena
var trail: PackedVector2Array = []
var hit_context: Dictionary = {}
var pierce_remaining := 0
var hit_enemy_ids: Dictionary = {}
var spawn_origin := Vector2.ZERO
var max_travel_distance := 0.0

func setup(owner_arena: BattleArena, at: Vector2, direction: Vector2, speed: float, power: float, enemy_projectile: bool, color: Color, size := 9.0, context: Dictionary = {}, pierce := 0, travel_limit := 0.0) -> void:
	arena = owner_arena
	global_position = at
	spawn_origin = at
	max_travel_distance = travel_limit
	velocity = direction.normalized() * speed
	damage = power
	hostile = enemy_projectile
	tint = color
	radius = size
	hit_context = context.duplicate(true)
	pierce_remaining = maxi(0, pierce)

func _process(delta: float) -> void:
	lifetime -= delta
	trail.append(global_position)
	if trail.size() > 9:
		trail.remove_at(0)
	global_position += velocity * delta
	rotation = velocity.angle()
	queue_redraw()
	if hostile:
		if is_instance_valid(arena.player) and global_position.distance_to(arena.player.global_position) <= radius + 17.0:
			arena.player.take_hit(damage)
			arena.impact(global_position, tint, 34.0, true)
			queue_free()
	else:
		for node in get_tree().get_nodes_in_group(&"battle_enemy"):
			var enemy := node as BattleEnemy
			if not is_instance_valid(enemy) or hit_enemy_ids.has(enemy.get_instance_id()):
				continue
			if global_position.distance_to(enemy.global_position) <= radius + enemy.body_radius():
				hit_enemy_ids[enemy.get_instance_id()] = true
				enemy.take_damage(damage, hit_context)
				arena.impact(global_position, tint, 42.0)
				if hit_context.get("projectile_aoe", false):
					arena.damage_area(global_position, float(hit_context.get("impact_radius", 55.0)), damage * 0.55, hit_context, enemy)
				if pierce_remaining <= 0:
					queue_free()
					return
				pierce_remaining -= 1
	if lifetime <= 0.0 or (max_travel_distance > 0.0 and spawn_origin.distance_to(global_position) > max_travel_distance) or not arena.WORLD_RECT.grow(120.0).has_point(global_position):
		queue_free()

func _draw() -> void:
	var primary := ArtDirection.DANGER if hostile else ArtDirection.CYAN
	var accent := ArtDirection.MAGENTA if hostile else ArtDirection.YELLOW
	var core := ArtDirection.VOID if hostile else ArtDirection.PAPER
	if trail.size() > 1:
		var local_trail := PackedVector2Array()
		for point in trail:
			local_trail.append(to_local(point))
		draw_polyline(local_trail, Color(ArtDirection.VOID.r, ArtDirection.VOID.g, ArtDirection.VOID.b, 0.84), radius * 1.55, false)
		draw_polyline(local_trail, Color(primary.r, primary.g, primary.b, 0.78), radius * 0.78, false)
		for index in range(0, local_trail.size(), 2):
			draw_rect(Rect2(local_trail[index] - Vector2(2, 2), Vector2(4, 4)), Color(accent.r, accent.g, accent.b, 0.78))
	var shadow := PackedVector2Array([
		Vector2(radius * 1.9, 4), Vector2(-radius * 0.8, -radius + 4),
		Vector2(-radius * 1.35, 4), Vector2(-radius * 0.8, radius + 4)
	])
	draw_colored_polygon(shadow, accent)
	var body := PackedVector2Array([
		Vector2(radius * 1.9, 0), Vector2(-radius * 0.8, -radius),
		Vector2(-radius * 1.35, 0), Vector2(-radius * 0.8, radius)
	])
	draw_colored_polygon(body, ArtDirection.VOID)
	var inner := PackedVector2Array([
		Vector2(radius * 1.45, 0), Vector2(-radius * 0.65, -radius * 0.62),
		Vector2(-radius, 0), Vector2(-radius * 0.65, radius * 0.62)
	])
	draw_colored_polygon(inner, primary)
	draw_line(Vector2(-radius * 0.45, 0), Vector2(radius * 0.85, 0), core, 3.0, false)
	if hostile:
		draw_circle(Vector2(radius * 0.35, 0), radius * 0.22, ArtDirection.MAGENTA)