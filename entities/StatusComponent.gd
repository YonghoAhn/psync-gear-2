## StatusComponent.gd
## 상태이상 스택 관리.
## 상태이상의 "실제 효과"(틱 피해 등)는 StatusApplier 가 담당한다.
## 이 컴포넌트는 "무엇이 얼마나 쌓여 있는가"만 추적한다.
##
## 상태이상 ID 예시:
##   &"burning", &"poisoned", &"shocked", &"wet",
##   &"frozen", &"slowed", &"bleeding"
extends Node
class_name StatusComponent


# =============================================================================
# 신호
# =============================================================================

## 상태이상이 추가되거나 스택이 변경될 때
signal status_changed(status_id: StringName, stacks: int)

## 상태이상이 완전히 제거될 때
signal status_cleared(status_id: StringName)


# =============================================================================
# 내부 상태
# =============================================================================

## { status_id: StringName → stacks: int }
var _stacks: Dictionary = {}

## { status_id: StringName → duration_remaining: float }
## duration <= 0 이면 영구 (스택 기반으로만 소멸)
var _durations: Dictionary = {}


# =============================================================================
# 공개 API — 스택 추가/제거
# =============================================================================

## 상태이상을 추가한다.
## duration <= 0 이면 지속시간 없음 (다른 방법으로만 제거).
func add_status(status_id: StringName, stacks: int = 1,
		duration: float = 0.0) -> void:
	_stacks[status_id]    = _stacks.get(status_id, 0) + stacks
	if duration > 0.0:
		# 지속시간은 최댓값으로 갱신 (덮어쓰기 방식)
		_durations[status_id] = maxf(_durations.get(status_id, 0.0), duration)

	status_changed.emit(status_id, _stacks[status_id])
	GlobalEventBus.status_applied.emit(get_parent(), status_id, stacks)


## 상태이상 스택을 amount 만큼 감소시킨다.
func reduce_stacks(status_id: StringName, amount: int = 1) -> void:
	if not _stacks.has(status_id):
		return
	_stacks[status_id] -= amount
	if _stacks[status_id] <= 0:
		clear_status(status_id)
	else:
		status_changed.emit(status_id, _stacks[status_id])


## 상태이상을 완전히 제거한다.
func clear_status(status_id: StringName) -> void:
	_stacks.erase(status_id)
	_durations.erase(status_id)
	status_cleared.emit(status_id)
	GlobalEventBus.status_removed.emit(get_parent(), status_id)


## 모든 상태이상을 제거한다.
func clear_all() -> void:
	var ids := _stacks.keys().duplicate()
	for id in ids:
		clear_status(id)


# =============================================================================
# 공개 API — 조회
# =============================================================================

func has_status(status_id: StringName) -> bool:
	return _stacks.get(status_id, 0) > 0


func get_stacks(status_id: StringName) -> int:
	return _stacks.get(status_id, 0)


func get_all_statuses() -> Dictionary:
	return _stacks.duplicate()


## 태그 배열 중 하나라도 보유 중이면 true
func has_any_status(status_ids: Array) -> bool:
	for id in status_ids:
		if has_status(id):
			return true
	return false


# =============================================================================
# 지속시간 처리
# =============================================================================

func _process(delta: float) -> void:
	var to_expire: Array = []
	for id in _durations:
		_durations[id] -= delta
		if _durations[id] <= 0.0:
			to_expire.append(id)
	for id in to_expire:
		clear_status(id)
