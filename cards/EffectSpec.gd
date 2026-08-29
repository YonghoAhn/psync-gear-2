## EffectSpec.gd
## 카드 효과 한 조각.
## 카드 하나는 EffectSpec 배열로 이루어진다.
## EffectExecutor 가 이 스펙을 읽고 실제 효과를 실행한다.
##
## 원칙: 이 파일 안에 실행 로직을 넣지 않는다.
##       오직 "무엇을 어떻게 할 것인가"의 데이터만 정의한다.
extends Resource
class_name EffectSpec


# =============================================================================
# 이펙트 타입 열거형
# =============================================================================

enum Type {
	## --- 피해 ---
	PROJECTILE,          ## 투사체 발사
	AREA_DAMAGE,         ## 범위 즉발 피해
	MELEE_DAMAGE,        ## 근접 즉발 피해 (근접 범위)

	## --- 장판 / 설치물 ---
	SPAWN_ZONE,          ## 장판 생성 (시간 지속, 진입 시 효과)
	SPAWN_INSTALLATION,  ## 설치물 생성 (포탑, 함정 등)

	## --- 상태이상 ---
	APPLY_STATUS,        ## 상태이상 적용
	REMOVE_STATUS,       ## 상태이상 제거

	## --- 소환 ---
	SPAWN_ENTITY,        ## 소환물 생성 (동료, 분신 등)

	## --- 자원 ---
	RESTORE_HP,          ## HP 회복
	RESTORE_MP,          ## MP 회복
	GRANT_SHIELD,        ## 보호막 부여

	## --- 이동 ---
	DASH_EFFECT,         ## 순간이동 / 강제 이동
	KNOCKBACK,           ## 넉백

	## --- 버프 ---
	APPLY_BUFF,          ## 시전자 스탯 모디파이어 추가
	REMOVE_BUFF,         ## 시전자 스탯 모디파이어 제거

	## --- 기타 ---
	CHAIN_EFFECT,        ## 다른 EffectSpec 을 연쇄 실행
}


# =============================================================================
# 공통 필드
# =============================================================================

## 이펙트 종류
@export var type: Type = Type.PROJECTILE

## 타겟 결정 방식
@export var target_spec: TargetSpec = null

## 발동 조건 (AND 조합 — 전부 true 여야 발동)
@export var conditions: Array[Resource] = []

## 속성 태그 (반응 시스템, ConditionSpec 판정에 사용)
## 예: [&"element_fire", &"projectile"]
@export var tags: Array[StringName] = []


# =============================================================================
# 수치 필드
# =============================================================================

## 피해/회복량 기본값
## 수식 지원: "attack_power * 1.5 + 10" 형태 문자열도 가능 (6단계에서 파서 추가)
## 지금은 float 고정값으로 사용
@export var power: float = 10.0

## 지속 시간 (장판, 버프, 상태이상 등) 초 단위. 0 = 영구
@export var duration: float = 0.0

## 틱 간격 (장판 틱 피해 등) 초 단위
@export var tick_interval: float = 1.0

## 반지름 / 크기 (AREA_DAMAGE, SPAWN_ZONE 등)
@export var radius: float = 80.0

## 발사체 속도 (PROJECTILE)
@export var projectile_speed: float = 400.0

## 발사체 관통 수 (0 = 관통 없음)
@export var pierce_count: int = 0

## 넉백 강도
@export var knockback_force: float = 0.0


# =============================================================================
# 참조 필드
# =============================================================================

## 생성할 엔티티/장판/설치물 씬 경로 (SPAWN_ZONE, SPAWN_INSTALLATION, SPAWN_ENTITY)
@export_file("*.tscn") var spawned_scene: String = ""

## APPLY_STATUS 에서 적용할 상태이상 ID
@export var status_id: StringName = &""

## APPLY_STATUS 에서 적용할 스택 수
@export var status_stacks: int = 1

## APPLY_BUFF 에서 사용할 모디파이어 정보
@export var buff_stat    : StringName = &""    ## 예: &"attack_power"
@export var buff_type    : String     = "flat" ## "flat" | "percent"
@export var buff_value   : float      = 0.0

## VFX 씬 경로 (이펙트 재생용)
@export_file("*.tscn") var vfx_scene: String = ""

## SFX 리소스 경로
@export_file("*.ogg","*.wav","*.mp3") var sfx: String = ""

## CHAIN_EFFECT 에서 연쇄 실행할 EffectSpec 목록
@export var chained_effects: Array[Resource] = []


# =============================================================================
# 실행 지연
# =============================================================================

## 이 이펙트 실행 전 대기 시간 (초). 연쇄 이펙트 타이밍 조정용.
@export var delay: float = 0.0
