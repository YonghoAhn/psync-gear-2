## ConditionSpec.gd
## 이펙트가 발동되는 조건을 정의하는 데이터.
## ConditionEvaluator 가 이 스펙을 평가해 true/false 를 반환한다.
##
## 여러 ConditionSpec 을 배열로 묶으면 AND 조건이 된다.
## OR 조건이 필요하면 별도 EffectSpec 으로 분리한다.
extends Resource
class_name ConditionSpec


# =============================================================================
# 조건 타입 열거형
# =============================================================================

enum Type {
	ALWAYS,              ## 항상 발동 (기본값)
	HP_BELOW_PERCENT,    ## 시전자 HP% 이하일 때
	HP_ABOVE_PERCENT,    ## 시전자 HP% 이상일 때
	TARGET_HAS_STATUS,   ## 대상이 특정 상태이상 보유 시
	TARGET_IS_BOSS,      ## 대상이 보스일 때
	TARGET_HAS_TAG,      ## 대상이 특정 태그 보유 시
	IS_CRIT,             ## 치명타 발생 시
	CASTER_HAS_STATUS,   ## 시전자가 특정 상태이상 보유 시
	ON_REACTION,         ## 특정 속성 반응 발생 시 (ReactionSystem 연동)
	RANDOM_CHANCE,       ## 일정 확률로 발동
}


# =============================================================================
# 필드
# =============================================================================

@export var type: Type = Type.ALWAYS

## HP_BELOW/ABOVE_PERCENT 에서 사용 (0.0 ~ 1.0)
@export var hp_threshold: float = 0.5

## TARGET_HAS_STATUS, CASTER_HAS_STATUS 에서 사용
@export var status_id: StringName = &""

## TARGET_HAS_TAG 에서 사용
@export var tag: StringName = &""

## ON_REACTION 에서 사용
@export var reaction_id: StringName = &""

## RANDOM_CHANCE 에서 사용 (0.0 ~ 1.0)
@export var chance: float = 0.3

## 조건을 반전시킨다 (NOT 조건)
@export var negate: bool = false


# =============================================================================
# 팩토리 헬퍼
# =============================================================================

static func always() -> ConditionSpec:
	var c := ConditionSpec.new()
	c.type = Type.ALWAYS
	return c

static func hp_below(threshold: float) -> ConditionSpec:
	var c := ConditionSpec.new()
	c.type         = Type.HP_BELOW_PERCENT
	c.hp_threshold = threshold
	return c

static func target_has_status(sid: StringName) -> ConditionSpec:
	var c := ConditionSpec.new()
	c.type      = Type.TARGET_HAS_STATUS
	c.status_id = sid
	return c

static func chance_of(probability: float) -> ConditionSpec:
	var c := ConditionSpec.new()
	c.type   = Type.RANDOM_CHANCE
	c.chance = probability
	return c

static func on_crit() -> ConditionSpec:
	var c := ConditionSpec.new()
	c.type = Type.IS_CRIT
	return c
