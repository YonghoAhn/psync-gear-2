## HealthComponent.gd
## HP 및 보호막 관리.
## 피해는 DamageReceiver 가 처리한 뒤 이 컴포넌트에 전달한다.
## 보호막이 있으면 HP 보다 먼저 소모된다.
extends Node
class_name HealthComponent


# =============================================================================
# 신호
# =============================================================================

signal hp_changed(new_hp: float, max_hp: float)
signal shield_changed(new_shield: float)
signal died()


# =============================================================================
# 상태
# =============================================================================

var _hp     : float = 0.0
var _shield : float = 0.0

## CombatStatsComponent 참조 (max_hp 조회용)
var _stats: CombatStatsComponent = null


# =============================================================================
# 초기화
# =============================================================================

func setup(stats: CombatStatsComponent) -> void:
	_stats = stats
	_hp    = _stats.max_hp
	hp_changed.emit(_hp, _stats.max_hp)


# =============================================================================
# 공개 API
# =============================================================================

var hp: float:
	get: return _hp
var shield: float:
	get: return _shield
var max_hp: float:
	get: return _stats.max_hp if _stats else 0.0

func is_alive() -> bool:
	return _hp > 0.0

func get_hp_ratio() -> float:
	if _stats == null or _stats.max_hp <= 0.0:
		return 0.0
	return _hp / _stats.max_hp


## 실제 피해를 적용한다. 보호막 먼저 소모.
## 반환값: 실제로 깎인 HP 양 (보호막 흡수분 제외)
func apply_damage(amount: float) -> float:
	if amount <= 0.0 or not is_alive():
		return 0.0

	var hp_damage := amount

	# 보호막 흡수
	if _shield > 0.0:
		var absorbed := minf(_shield, amount)
		_shield   -= absorbed
		hp_damage -= absorbed
		shield_changed.emit(_shield)

	if hp_damage <= 0.0:
		return 0.0

	# HP 감소
	_hp = maxf(0.0, _hp - hp_damage)
	hp_changed.emit(_hp, _stats.max_hp)

	if _hp <= 0.0:
		died.emit()

	return hp_damage


## HP를 회복한다. max_hp 초과 불가.
func heal(amount: float) -> void:
	if amount <= 0.0 or not is_alive():
		return
	_hp = minf(_hp + amount, _stats.max_hp)
	hp_changed.emit(_hp, _stats.max_hp)


## 보호막을 추가한다. 중첩 가능.
func add_shield(amount: float) -> void:
	var recovery_multiplier := _stats.shield_recovery if _stats else 1.0
	_shield += maxf(0.0, amount) * recovery_multiplier
	shield_changed.emit(_shield)


## HP를 최대치로 완전 회복한다 (스테이지 클리어 후 등).
func full_restore() -> void:
	_hp = _stats.max_hp
	hp_changed.emit(_hp, _stats.max_hp)


## max_hp 가 변경되었을 때 호출 (모디파이어 추가/제거 후).
## 현재 HP 비율을 유지하거나 최대값에 맞게 클램프한다.
func on_max_hp_changed() -> void:
	_hp = minf(_hp, _stats.max_hp)
	hp_changed.emit(_hp, _stats.max_hp)
