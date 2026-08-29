## AbilityAnchor.gd
## 이펙트/투사체 생성 위치 레지스트리.
## 엔티티 씬 안에 Marker2D 노드들을 등록해두면
## EffectExecutor 가 이름으로 위치를 조회할 수 있다.
##
## 사용 예:
##   entity.ability_anchor.get_point(&"muzzle")   → 총구 위치
##   entity.ability_anchor.get_point(&"center")   → 중심
##   entity.ability_anchor.get_point(&"overhead")  → 머리 위
extends Node
class_name AbilityAnchor


# =============================================================================
# 앵커 포인트 등록
# =============================================================================

## { name: StringName → Marker2D }
var _anchors: Dictionary = {}


## Marker2D 노드를 이름으로 등록한다.
func register(anchor_name: StringName, marker: Marker2D) -> void:
	_anchors[anchor_name] = marker


## 노드 경로로 자동 등록 (씬 설정 편의용).
## path 예: "Anchors/Muzzle"
func register_by_path(anchor_name: StringName, path: NodePath) -> void:
	var node := get_node_or_null(path)
	if node is Marker2D:
		_anchors[anchor_name] = node
	else:
		push_warning("AbilityAnchor: '%s' 경로에 Marker2D 없음" % path)


# =============================================================================
# 조회 API
# =============================================================================

## 글로벌 위치 반환. 등록되지 않은 이름이면 부모 위치 반환.
func get_point(anchor_name: StringName) -> Vector2:
	if _anchors.has(anchor_name):
		return _anchors[anchor_name].global_position
	# 폴백: 엔티티 중심
	var parent := get_parent()
	if parent is Node2D:
		return (parent as Node2D).global_position
	push_warning("AbilityAnchor: '%s' 앵커 없음, 폴백 Vector2.ZERO" % anchor_name)
	return Vector2.ZERO


## 등록된 앵커 이름 목록
func get_anchor_names() -> Array:
	return _anchors.keys()


## 특정 앵커가 등록되어 있는지 확인
func has_anchor(anchor_name: StringName) -> bool:
	return _anchors.has(anchor_name)
