## ManaComponent.gd
## MP 관리. 자연 회복, 소모, 강제 세팅을 처리한다.
## 쿨타임 없음 — MP 가 곧 난사 제한이다.
extends Node
class_name ManaComponent


# =============================================================================
# 신호
# =============================================================================

signal mp_changed(new_mp: float, max_mp: float)


# =============================================================================
# 상태
# =============================================================================

var _mp    : float = 0.0
var _stats : CombatStatsComponent = null

## 회복 일시정지 여부 (홀드 시전 중 등)
var regen_paused: bool = false


# =============================================================================
# 초기화
# =============================================================================

func setup(stats: CombatStatsComponent) -> void:
	_stats = stats
	_mp    = _stats.max_mp
	mp_changed.emit(_mp, _stats.max_mp)


# =============================================================================
# 공개 API
# =============================================================================

var mp: float:
	get: return _mp
var max_mp: float:
	get: return _stats.max_mp if _stats else 0.0

func get_mp_ratio() -> float:
	if _stats == null or _stats.max_mp <= 0.0:
		return 0.0
	return _mp / _stats.max_mp


## MP 가 amount 이상 있는지 확인 (카드 사용 전 체크).
func has_enough(amount: float) -> bool:
	return _mp >= amount


## MP 를 소모한다. 성공 여부 반환.
func spend(amount: float) -> bool:
	if not has_enough(amount):
		return false
	_mp -= amount
	mp_changed.emit(_mp, _stats.max_mp)
	return true


## MP 를 회복한다. max_mp 초과 불가.
func restore(amount: float) -> void:
	_mp = minf(_mp + amount, _stats.max_mp)
	mp_changed.emit(_mp, _stats.max_mp)


## MP 를 최대치로 완전 회복한다.
func full_restore() -> void:
	_mp = _stats.max_mp
	mp_changed.emit(_mp, _stats.max_mp)


# =============================================================================
# 자연 회복 (매 프레임 호출)
# =============================================================================

func _process(delta: float) -> void:
	if regen_paused or _stats == null:
		return
	if _mp >= _stats.max_mp:
		return
	restore(_stats.mp_regen * delta)
