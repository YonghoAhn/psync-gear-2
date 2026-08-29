## CardDef.gd
## 카드 "종류" 정의. 이 Resource 하나가 카드 한 종류를 나타낸다.
## 실제 덱에는 CardInstance 가 들어가며, CardInstance 가 이 Resource 를 참조한다.
##
## 새 카드 추가 = 새 CardDef .tres 파일 생성 + EffectSpec 조합.
## 스크립트 추가 없음.
extends Resource
class_name CardDef


# =============================================================================
# 분류 열거형
# =============================================================================

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	HEROIC,
	LEGENDARY,
}

enum Role {
	ATTACK,
	DEFENSE,
	UTILITY,
}

enum DeliveryType {
	INSTANT,
	PROJECTILE,
	INSTALLATION_OR_SUMMON,
	STATUS,
	MOVEMENT,
}

enum AttackPattern {
	MELEE_ARC,
	THRUST,
	PROJECTILE,
	NOVA,
	ZONE,
	DEFENSE,
	MOVEMENT,
}

enum TargetPriority {
	NEAREST,
	LOWEST_HP,
	RANDOM,
	DENSEST_CLUSTER,
	SELF,
}

enum Category {
	ATTACK,      ## 공격 카드
	SUPPORT,     ## 지원 / 회복 카드
	ENVIRONMENT, ## 장판 / 설치물 / 환경 변화 카드
}

enum CastType {
	INSTANT,     ## 즉발 (클릭 즉시 발동)
	HOLD,        ## 홀드 시전 (버튼 유지 후 발동)
}


# =============================================================================
# 식별 정보
# =============================================================================

@export var id          : StringName = &""
@export var display_name: String     = ""
@export var description : String     = ""   ## 인게임 카드 설명문 (수식 치환 예정)


# =============================================================================
# 분류
# =============================================================================

@export var rarity   : Rarity   = Rarity.COMMON
@export var category : Category = Category.ATTACK
@export var cast_type: CastType = CastType.INSTANT
@export var role: Role = Role.ATTACK
@export var delivery_type: DeliveryType = DeliveryType.INSTANT

## 기획의 큰 카테고리 -> 작은 카테고리 -> 카드군 계층.
@export var large_category: StringName = &""
@export var small_category: StringName = &""
@export var family_id: StringName = &""
@export var is_neutral: bool = false

## 메인 타입 태그 (덱 편향 계산에 사용) 예: &"projectile", &"zone", &"buff"
@export var main_type: StringName = &""

## 서브 타입 태그들 예: [&"fire", &"single_target"]
@export var sub_types: Array[StringName] = []


# =============================================================================
# 비용
# =============================================================================

@export var mp_cost: float = 20.0




## 자동 사이클에서 다음 카드로 넘어가기 전 기본 간격.
## 효과의 비동기 처리와 무관하게 발동 순간부터 감소한다.
@export var execution_interval: float = 0.45

## 발동 예약 후 실제 효과가 해소되기까지의 선딜레이.
## CycleRunner는 이 시간을 기다리지 않고 execution_interval을 즉시 계산한다.
@export var effect_delay: float = 0.0

## 전투 공간 판정. 공격 카드는 이 거리 밖의 대상을 절대 타격하지 않는다.
@export var attack_pattern: AttackPattern = AttackPattern.MELEE_ARC
@export var max_range: float = 140.0
@export var impact_radius: float = 34.0
@export var arc_degrees: float = 110.0
@export var projectile_speed: float = 650.0
@export var projectile_count: int = 1
@export var base_power: float = 13.0
@export var target_priority: TargetPriority = TargetPriority.NEAREST
@export var target_count: int = 1
@export var status_id: StringName = &""
@export var status_stacks: int = 0
@export var status_duration: float = 0.0
@export var knockback_force: float = 0.0
@export var hit_count: int = 1
@export var pierce_count: int = 0
@export var active_limit: int = 0
@export var summon_kind: StringName = &""
@export var special_rule: StringName = &""


# =============================================================================
# 시전 설정
# =============================================================================

## 홀드 시전 시간 (HOLD 타입만 사용, 초)
@export var hold_duration: float = 1.0


# =============================================================================
# 이펙트 목록 — 카드의 핵심
# =============================================================================

## 이 카드가 발동하는 이펙트 목록.
## 순서대로 실행된다. delay 필드로 타이밍 조정 가능.
@export var effect_specs: Array[Resource] = []


# =============================================================================
# 강화 관련
# =============================================================================

## 강화 레벨별 변경사항을 정의한 Resource (6단계 UpgradePolicy 에서 사용)
## null 이면 강화 불가
@export var upgrade_def: Resource = null


# =============================================================================
# 태그 (속성 반응, ConditionSpec 판정)
# =============================================================================

## 예: [&"element_fire", &"aoe"]
@export var card_tags: Array[StringName] = []


# =============================================================================
# 비주얼 / 오디오
# =============================================================================

@export var icon        : Texture2D = null
@export_file("*.tscn") var cast_vfx : String = ""
@export_file("*.ogg","*.wav","*.mp3") var cast_sfx: String = ""


# =============================================================================
# 편의 메서드
# =============================================================================

## 이 카드가 발동 가능한지 MP 체크
func can_cast(current_mp: float) -> bool:
	return current_mp >= mp_cost


## 카드의 모든 태그 (card_tags + main_type + sub_types 통합)
func get_all_tags() -> Array[StringName]:
	var result: Array[StringName] = card_tags.duplicate()
	if main_type != &"":
		result.append(main_type)
	result.append_array(sub_types)
	return result

func targeting_labels() -> Array[String]:
	var distance := "근거리"
	match attack_pattern:
		AttackPattern.PROJECTILE, AttackPattern.THRUST:
			distance = "원거리" if max_range >= 300.0 else "근거리"
		AttackPattern.NOVA:
			distance = "자기중심" if target_priority == TargetPriority.SELF else "원거리"
		AttackPattern.ZONE:
			distance = "장판"
		AttackPattern.DEFENSE:
			distance = "설치" if delivery_type == DeliveryType.INSTALLATION_OR_SUMMON else "자기중심"
		_:
			pass
	if summon_kind != &"":
		distance = "소환" if summon_kind in [&"golem", &"spirit"] else "설치"
	var shape := "한 명"
	match attack_pattern:
		AttackPattern.MELEE_ARC: shape = "부채꼴"
		AttackPattern.THRUST: shape = "직선"
		AttackPattern.NOVA, AttackPattern.ZONE: shape = "범위"
		AttackPattern.PROJECTILE: shape = "다중" if projectile_count > 1 or target_count > 1 else "한 명"
		AttackPattern.DEFENSE, AttackPattern.MOVEMENT: shape = "자신"
	var priority: String = ["가까운 적", "딸피 우선", "랜덤", "밀집 지역", "자신"][target_priority]
	return [distance, shape, priority]