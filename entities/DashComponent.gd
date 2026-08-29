## DashComponent.gd
## 대시 처리. 쿨다운, 대시 지속시간, i-frame 을 관리한다.
## 실제 이동 적용은 MovementComponent 가 아닌 이 컴포넌트가 직접 처리한다.
## (대시 중에는 일반 이동 입력을 무시해야 하기 때문)
extends Node
class_name DashComponent


# =============================================================================
# 신호
# =============================================================================

signal dash_started(direction: Vector2)
signal dash_ended()


# =============================================================================
# 설정값 (CharacterDef 에서 주입 예정, 지금은 export 로 직접 설정)
# =============================================================================

@export var dash_speed       : float = 600.0  ## px/초
@export var dash_duration    : float = 0.15   ## 초
@export var dash_cooldown    : float = 0.8    ## 초
@export var iframe_duration  : float = 0.2    ## 대시 중 무적 시간


# =============================================================================
# 내부 상태
# =============================================================================

var _body        : CharacterBody2D = null
var _receiver    : DamageReceiver  = null
var _movement    : MovementComponent = null

var _is_dashing  : bool  = false
var _dash_timer  : float = 0.0   ## 대시 지속 시간 카운트다운
var _cd_timer    : float = 0.0   ## 쿨다운 카운트다운
var _dash_dir    : Vector2 = Vector2.ZERO


# =============================================================================
# 초기화
# =============================================================================

func setup(body: CharacterBody2D,
		receiver: DamageReceiver,
		movement: MovementComponent) -> void:
	_body     = body
	_receiver = receiver
	_movement = movement


# =============================================================================
# 공개 API
# =============================================================================

var is_dashing: bool:
	get: return _is_dashing
var can_dash: bool:
	get: return _cd_timer <= 0.0 and not _is_dashing

## 대시를 시도한다.
## direction: 대시 방향 (정규화 불필요). Zero 면 마지막 입력 방향 사용.
func try_dash(direction: Vector2 = Vector2.ZERO) -> bool:
	if not can_dash:
		return false

	# 방향 결정: 입력 > 마지막 이동 방향 > 오른쪽 폴백
	if direction != Vector2.ZERO:
		_dash_dir = direction.normalized()
	elif _movement and _movement.get_facing_direction() != Vector2.ZERO:
		_dash_dir = _movement.get_facing_direction()
	else:
		_dash_dir = Vector2.RIGHT

	_is_dashing  = true
	_dash_timer  = dash_duration
	_cd_timer    = dash_cooldown

	# 대시 중 이동 잠금
	if _movement:
		_movement.locked = true

	# 무적 부여
	if _receiver:
		_receiver.grant_invincibility(iframe_duration)

	dash_started.emit(_dash_dir)
	return true


# =============================================================================
# 프레임 처리
# =============================================================================

func _physics_process(delta: float) -> void:
	if _body == null:
		return

	# 쿨다운 감소
	if _cd_timer > 0.0:
		_cd_timer -= delta

	# 대시 진행 중
	if _is_dashing:
		_dash_timer -= delta
		_body.velocity = _dash_dir * dash_speed
		_body.move_and_slide()

		if _dash_timer <= 0.0:
			_end_dash()


func _end_dash() -> void:
	_is_dashing = false
	if _movement:
		_movement.locked = false
	dash_ended.emit()
