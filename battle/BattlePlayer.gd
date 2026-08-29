extends CharacterBody2D
class_name BattlePlayer

signal died
signal health_changed(hp: float, max_hp: float, shield: float)
signal consumable_changed(name: String, count: int)
signal consumable_inventory_changed(snapshot: Array, selected_index: int)
signal consumable_use_failed(slot_index: int)

var max_hp := 100.0
var hp := 100.0
var shield := 0.0
var move_speed := 260.0
var dodge_speed := 760.0
var dodge_duration := 0.14
var dodge_cooldown := 0.75
var _dodge_left := 0.0
var _cooldown_left := 0.0
var _invincible_left := 0.0
var _dodge_direction := Vector2.RIGHT
var _defense_left := 0.0
var _haste_left := 0.0
var _anim_time := 0.0
var arena_rect := Rect2(40, 80, 1200, 590)
var consumables := [
	{"name": "회복 드링크", "count": 2, "kind": "heal"},
	{"name": "철벽 토닉", "count": 1, "kind": "defense"},
	{"name": "가속 엘릭서", "count": 1, "kind": "haste"},
]
var selected_consumable := 0
var consumables_enabled := false
var facing_direction := Vector2.RIGHT

func setup(character: CharacterDef) -> void:
	max_hp = character.base_max_hp
	hp = max_hp
	move_speed = character.base_move_speed
	dodge_speed = character.dodge_speed
	dodge_duration = character.dodge_duration
	dodge_cooldown = character.dodge_cooldown
	queue_redraw()

func _ready() -> void:
	add_to_group(&"battle_player")
	_emit_consumable()

## 전투 화면 위의 HUD/Control이 클릭을 소비하더라도 반드시 전투 입력을 받는다.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		try_dodge()
	elif consumables_enabled and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if not use_consumable():
			consumable_use_failed.emit(selected_consumable)
	elif consumables_enabled and event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		selected_consumable = wrapi(selected_consumable + (1 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1), 0, consumables.size())
		_emit_consumable()

func _physics_process(delta: float) -> void:
	_anim_time += delta
	_cooldown_left = maxf(0.0, _cooldown_left - delta)
	_invincible_left = maxf(0.0, _invincible_left - delta)
	_defense_left = maxf(0.0, _defense_left - delta)
	_haste_left = maxf(0.0, _haste_left - delta)
	if _dodge_left > 0.0:
		_dodge_left -= delta
		velocity = _dodge_direction * dodge_speed
		if int(_anim_time * 70.0) % 3 == 0:
			_spawn_afterimage()
	else:
		var movement_input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
		if movement_input != Vector2.ZERO:
			facing_direction = movement_input.normalized()
		velocity = movement_input * move_speed * (1.35 if _haste_left > 0.0 else 1.0)
	move_and_slide()
	global_position.x = clampf(global_position.x, arena_rect.position.x, arena_rect.end.x)
	global_position.y = clampf(global_position.y, arena_rect.position.y, arena_rect.end.y)
	queue_redraw()

func try_dodge() -> bool:
	if _cooldown_left > 0.0:
		return false
	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if input == Vector2.ZERO:
		input = facing_direction
	_dodge_direction = input if input != Vector2.ZERO else Vector2.RIGHT
	facing_direction = _dodge_direction
	_dodge_left = dodge_duration
	_cooldown_left = dodge_cooldown
	_invincible_left = dodge_duration + 0.09
	_spawn_afterimage()
	return true

func take_hit(amount: float) -> void:
	if _invincible_left > 0.0 or hp <= 0.0:
		return
	if _defense_left > 0.0:
		amount *= 0.55
	var shield_damage := minf(shield, amount)
	shield -= shield_damage
	hp = maxf(0.0, hp - (amount - shield_damage))
	health_changed.emit(hp, max_hp, shield)
	_invincible_left = 0.28
	_spawn_vfx(CombatVfx.Kind.IMPACT, ArtDirection.DANGER, 45.0, 0.28, CombatVfx.Side.HOSTILE)
	if hp <= 0.0:
		died.emit()

func use_consumable() -> bool:
	var item: Dictionary = consumables[selected_consumable]
	if int(item["count"]) <= 0:
		return false
	match String(item["kind"]):
		"heal":
			if hp >= max_hp:
				return false
			hp = minf(max_hp, hp + max_hp * 0.38)
			_spawn_vfx(CombatVfx.Kind.HEAL, ArtDirection.MAGENTA, 78.0, 0.65)
		"defense":
			shield += 35.0
			_defense_left = 8.0
			_spawn_vfx(CombatVfx.Kind.SHIELD, ArtDirection.CYAN, 82.0, 0.7)
		"haste":
			_haste_left = 9.0
			_spawn_vfx(CombatVfx.Kind.RING, ArtDirection.YELLOW, 90.0, 0.6)
	item["count"] = int(item["count"]) - 1
	consumables[selected_consumable] = item
	health_changed.emit(hp, max_hp, shield)
	_emit_consumable()
	return true

## 이전 테스트/호출 호환성.
func use_potion() -> bool:
	selected_consumable = 0
	return use_consumable()

func grant_shield(amount: float) -> void:
	shield += amount
	health_changed.emit(hp, max_hp, shield)
	_spawn_vfx(CombatVfx.Kind.SHIELD, ArtDirection.CYAN, 70.0, 0.55)

func dodge_ratio() -> float:
	return _cooldown_left / dodge_cooldown if dodge_cooldown > 0.0 else 0.0

func _emit_consumable() -> void:
	var item: Dictionary = consumables[selected_consumable]
	consumable_changed.emit("%s  [휠 변경]" % item["name"], int(item["count"]))
	consumable_inventory_changed.emit(get_consumable_snapshot(), selected_consumable)

func get_consumable_snapshot() -> Array:
	var result: Array = []
	for index in range(consumables.size()):
		var source: Dictionary = consumables[index]
		result.append({
			"slot_index": index,
			"name": String(source.get("name", "EMPTY")),
			"kind": String(source.get("kind", "")),
			"count": int(source.get("count", 0)),
			"selected": index == selected_consumable,
		})
	return result

func _spawn_afterimage() -> void:
	_spawn_vfx(CombatVfx.Kind.AFTERIMAGE, ArtDirection.CYAN, 23.0, 0.28)

func _spawn_vfx(kind: CombatVfx.Kind, color: Color, radius: float, life: float, effect_side := CombatVfx.Side.FRIENDLY) -> void:
	if not is_inside_tree():
		return
	var effect := CombatVfx.create(kind, global_position, color, radius, life, _dodge_direction, 100.0, effect_side)
	get_parent().add_child(effect)

func _draw() -> void:
	var aim := facing_direction
	if aim == Vector2.ZERO:
		aim = Vector2.RIGHT
	var pulse := 1.0 + sin(_anim_time * 7.0) * 0.035
	# Cyan under-print, black cape, pink dress: the same sticker language as the pilot art.
	var cape := PackedVector2Array([
		Vector2(-22, 17), Vector2(-15, -9), Vector2(0, -20),
		Vector2(17, -8), Vector2(23, 20), Vector2(0, 14)
	])
	var cape_shadow := PackedVector2Array()
	for point in cape:
		cape_shadow.append(point + Vector2(4, 4))
	draw_colored_polygon(cape_shadow, ArtDirection.CYAN)
	draw_colored_polygon(cape, ArtDirection.VOID)
	var dress := PackedVector2Array([Vector2(-12, -4), Vector2(12, -4), Vector2(17, 21), Vector2(-17, 21)])
	draw_colored_polygon(dress, ArtDirection.MAGENTA)
	draw_line(Vector2(-14, 11), Vector2(14, 11), ArtDirection.VOID, 3.0)
	# Tiny adult chibi face with deliberately crude features.
	draw_circle(Vector2(0, -14), 12.5 * pulse, ArtDirection.VOID)
	draw_circle(Vector2(0, -14), 10.0 * pulse, ArtDirection.PAPER)
	draw_arc(Vector2(0, -17), 10.5, PI, TAU, 10, ArtDirection.PINK, 6.0, false)
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -24), Vector2(-14, -33), Vector2(-3, -27)]), ArtDirection.VIOLET)
	draw_colored_polygon(PackedVector2Array([Vector2(8, -24), Vector2(14, -33), Vector2(3, -27)]), ArtDirection.VIOLET)
	draw_circle(Vector2(-4, -14), 2.2, ArtDirection.VOID)
	draw_line(Vector2(2, -15), Vector2(7, -15), ArtDirection.VOID, 2.0)
	draw_line(Vector2(-2, -9), Vector2(3, -9), ArtDirection.MAGENTA, 2.0)
	# Broad cutout blade with paper core and yellow registration tick.
	draw_line(aim * 7.0, aim * 38.0, ArtDirection.VOID, 10.0, false)
	draw_line(aim * 8.0, aim * 36.0, ArtDirection.PAPER, 5.0, false)
	draw_line(aim * 22.0, aim * 37.0, ArtDirection.PINK, 2.0, false)
	draw_line(aim.rotated(PI * 0.5) * 6.0 + aim * 11.0, aim.rotated(-PI * 0.5) * 6.0 + aim * 11.0, ArtDirection.YELLOW, 4.0, false)
	if shield > 0.0 or _defense_left > 0.0:
		draw_arc(Vector2.ZERO, 31.0, -PI * 0.75, PI * 0.75, 18, ArtDirection.VOID, 8.0, false)
		draw_arc(Vector2.ZERO, 31.0, -PI * 0.75, PI * 0.75, 18, ArtDirection.CYAN, 4.0, false)