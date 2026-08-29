## MovementComponent.gd
## 속도 기반 이동 처리.
## CharacterBody2D 를 부모로 가정하며, move_and_slide() 를 호출한다.
## 넉백 충격량은 감쇠 벡터로 관리된다.
extends Node
class_name MovementComponent


# =============================================================================
# 내부 상태
# =============================================================================

var _stats      : CombatStatsComponent = null
var _body       : CharacterBody2D      = null

## 이동 입력 방향 (정규화된 Vector2)
var _input_dir  : Vector2 = Vector2.ZERO

## 넉백 속도 (매 프레임 감쇠)
var _knockback  : Vector2 = Vector2.ZERO

## 이동 잠금 (홀드 시전 경직 등 사용)
var locked      : bool = false

## 넉백 감쇠 계수 (1초에 몇 배로 줄어드는지)
const KNOCKBACK_DECAY : float = 8.0


# =============================================================================
# 초기화
# =============================================================================

func setup(body: CharacterBody2D, stats: CombatStatsComponent) -> void:
	_body  = body
	_stats = stats


# =============================================================================
# 공개 API
# =============================================================================

## 이동 방향을 설정한다 (PlayerController / EnemyAI 에서 매 프레임 호출).
func set_input_direction(dir: Vector2) -> void:
	_input_dir = dir.normalized() if dir != Vector2.ZERO else Vector2.ZERO


## 넉백 충격량을 추가한다.
func apply_knockback(impulse: Vector2) -> void:
	_knockback += impulse


## 이동을 완전히 멈춘다 (텔레포트, 빙결 등).
func stop() -> void:
	_input_dir = Vector2.ZERO
	_knockback = Vector2.ZERO
	if _body:
		_body.velocity = Vector2.ZERO


# =============================================================================
# 프레임 처리
# =============================================================================

func _physics_process(delta: float) -> void:
	if _body == null or _stats == null:
		return

	# 이동 속도 계산
	var move_vel := Vector2.ZERO
	if not locked:
		move_vel = _input_dir * _stats.move_speed

	# 넉백 감쇠
	_knockback = _knockback.move_toward(Vector2.ZERO,
		_knockback.length() * KNOCKBACK_DECAY * delta)

	_body.velocity = move_vel + _knockback
	_body.move_and_slide()


## 현재 실제 이동 방향 (UI, 애니메이션용)
func get_facing_direction() -> Vector2:
	if _body == null:
		return Vector2.ZERO
	return _body.velocity.normalized() if _body.velocity != Vector2.ZERO else _input_dir
