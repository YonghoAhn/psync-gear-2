## StatusApplier.gd
## 상태이상의 "실제 효과"를 매 틱마다 처리한다.
## StatusComponent 는 "얼마나 쌓여있는가"만 추적하고,
## 이 시스템이 틱 피해 / 이동 감속 등 실제 영향을 적용한다.
##
## 배치: EntityBase 자식 노드로 추가.
## StatusComponent 와 DamageReceiver 를 참조해 동작한다.
extends Node
class_name StatusApplier


# =============================================================================
# 상태이상 정의 테이블
## 새 상태이상 추가 = 이 딕셔너리에 항목 하나 추가
# =============================================================================

## { status_id: { "tick_damage_per_stack": float, "move_slow": float (0~1) } }
const STATUS_DEFS : Dictionary = {
	&"burning": {
		"tick_damage_per_stack" : 3.0,
		"move_slow"             : 0.0,
		"tick_interval"         : 0.5,
		"tags"                  : [&"element_fire"],
	},
	&"poisoned": {
		"tick_damage_per_stack" : 2.0,
		"move_slow"             : 0.0,
		"tick_interval"         : 0.5,
		"tags"                  : [&"element_poison"],
	},
	&"shocked": {
		"tick_damage_per_stack" : 1.5,
		"move_slow"             : 0.0,
		"tick_interval"         : 0.3,
		"tags"                  : [&"element_electric"],
	},
	&"wet": {
		"tick_damage_per_stack" : 0.0,
		"move_slow"             : 0.0,
		"tick_interval"         : 1.0,
		"tags"                  : [&"surface_wet"],
	},
	&"slowed": {
		"tick_damage_per_stack" : 0.0,
		"move_slow"             : 0.4,   ## 이동속도 40% 감소
		"tick_interval"         : 1.0,
		"tags"                  : [],
	},
	&"bleeding": {
		"tick_damage_per_stack" : 4.0,
		"move_slow"             : 0.0,
		"tick_interval"         : 0.5,
		"tags"                  : [&"physical"],
	},
}


# =============================================================================
# 내부 상태
# =============================================================================

var _status   : StatusComponent  = null
var _receiver : DamageReceiver   = null
var _stats    : CombatStatsComponent = null
var _movement : MovementComponent    = null

## { status_id: float } — 각 상태이상의 틱 타이머
var _tick_timers : Dictionary = {}


# =============================================================================
# 초기화
# =============================================================================

func setup(status: StatusComponent,
		receiver: DamageReceiver,
		stats: CombatStatsComponent,
		movement: MovementComponent = null) -> void:
	_status   = status
	_receiver = receiver
	_stats    = stats
	_movement = movement

	_status.status_changed.connect(_on_status_changed)
	_status.status_cleared.connect(_on_status_cleared)


# =============================================================================
# 틱 처리
# =============================================================================

func _process(delta: float) -> void:
	if _status == null:
		return

	_apply_move_slow()

	for status_id in _status.get_all_statuses():
		var def : Dictionary = STATUS_DEFS.get(status_id, {})
		if def.is_empty():
			continue

		# 틱 타이머 감소
		_tick_timers[status_id] = _tick_timers.get(status_id, 0.0) - delta
		if _tick_timers[status_id] > 0.0:
			continue

		# 틱 실행
		_tick_timers[status_id] = def.get("tick_interval", 1.0)
		var dmg_per_stack : float = def.get("tick_damage_per_stack", 0.0)
		if dmg_per_stack <= 0.0:
			continue

		var stacks : int = _status.get_stacks(status_id)
		var damage : float = dmg_per_stack * stacks

		_receiver.receive_damage(damage, def.get("tags", []), null, false)
		GlobalEventBus.status_ticked.emit(
			get_parent(), status_id, damage)


# =============================================================================
# 이동 감속 적용
# =============================================================================

func _apply_move_slow() -> void:
	if _movement == null or _stats == null:
		return

	var total_slow := 0.0
	for status_id in _status.get_all_statuses():
		var def : Dictionary = STATUS_DEFS.get(status_id, {})
		total_slow += def.get("move_slow", 0.0)

	total_slow = clampf(total_slow, 0.0, 0.9)   ## 최대 90% 감속

	## CombatStatsComponent 에 slow 모디파이어 적용
	_stats.remove_modifiers_by_source(&"status_slow")
	if total_slow > 0.0:
		_stats.add_modifier(&"status_slow", &"move_speed", "percent",
			-total_slow * 100.0)


# =============================================================================
# 신호 수신
# =============================================================================

func _on_status_changed(status_id: StringName, _stacks: int) -> void:
	## 상태이상이 새로 추가되면 타이머 초기화
	if not _tick_timers.has(status_id):
		var def : Dictionary = STATUS_DEFS.get(status_id, {})
		_tick_timers[status_id] = def.get("tick_interval", 1.0)


func _on_status_cleared(status_id: StringName) -> void:
	_tick_timers.erase(status_id)
	## 이동 감속 재계산
	_apply_move_slow()
