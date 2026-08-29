## TargetSpec.gd
## 이펙트가 "누구/어디에" 적용될지를 정의하는 데이터.
## EffectExecutor 가 이 스펙을 TargetResolver 에 넘겨 실제 대상을 구한다.
##
## 카드 스크립트에 타겟 로직을 넣지 않는다.
## 오직 이 Resource 의 type + 파라미터 조합만으로 타겟을 결정한다.
extends Resource
class_name TargetSpec


# =============================================================================
# 타겟 타입 열거형
# =============================================================================

enum Type {
	MOUSE_DIRECTION,      ## Legacy alias: nearest enemy direction
	MOUSE_POSITION,       ## Legacy alias: densest enemy cluster
	SELF,
	NEAREST_ENEMY,
	RANDOM_ENEMIES,
	ALL_ENEMIES_IN_RANGE,
	STATUS_PRIORITY,
	INSTALL_POINT,
	ANCHOR_POINT,
	LOWEST_HP,
	DENSEST_CLUSTER,
}


# =============================================================================
# 필드
# =============================================================================

## 타겟 결정 방식
@export var type: Type = Type.NEAREST_ENEMY

## 범위 (ALL_ENEMIES_IN_RANGE, NEAREST_ENEMY 등에서 사용, px)
@export var range: float = 300.0

## 대상 수 (RANDOM_ENEMIES 등에서 사용)
@export var count: int = 1

## 우선 상태이상 ID (STATUS_PRIORITY 에서 사용)
@export var priority_status: StringName = &""

## AbilityAnchor 포인트 이름 (ANCHOR_POINT 에서 사용)
@export var anchor_name: StringName = &"muzzle"

## 대상이 없을 때 시전을 취소할지 여부
@export var cancel_if_no_target: bool = false


# =============================================================================
# 팩토리 헬퍼 (GDScript 에서 인스턴스 생성 편의용)
# =============================================================================

static func mouse_dir() -> TargetSpec:
	var s := TargetSpec.new()
	s.type = Type.MOUSE_DIRECTION
	return s

static func mouse_pos() -> TargetSpec:
	var s := TargetSpec.new()
	s.type = Type.MOUSE_POSITION
	return s

static func self_target() -> TargetSpec:
	var s := TargetSpec.new()
	s.type = Type.SELF
	return s

static func nearest(range_px: float = 300.0) -> TargetSpec:
	var s := TargetSpec.new()
	s.type  = Type.NEAREST_ENEMY
	s.range = range_px
	return s

static func aoe(range_px: float = 200.0) -> TargetSpec:
	var s := TargetSpec.new()
	s.type  = Type.ALL_ENEMIES_IN_RANGE
	s.range = range_px
	return s

static func lowest_hp(range_px: float = 300.0) -> TargetSpec:
	var s := TargetSpec.new()
	s.type = Type.LOWEST_HP
	s.range = range_px
	return s

static func densest(range_px: float = 500.0) -> TargetSpec:
	var s := TargetSpec.new()
	s.type = Type.DENSEST_CLUSTER
	s.range = range_px
	return s