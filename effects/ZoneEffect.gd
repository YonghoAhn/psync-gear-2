## ZoneEffect.gd
## 장판(Zone) 씬 스크립트.
## 지정한 시간 동안 유지되며 진입한 적에게 틱 피해 + 상태이상을 적용한다.
## EffectExecutor 가 initialize() 로 데이터를 주입한다.
##
## ZoneEffect.tscn 노드 트리:
##   Area2D              [이름: ZoneEffect, Script: ZoneEffect.gd]
##   ├── CollisionShape2D [CircleShape2D]
##   └── Sprite2D / CPUParticles2D  [시각 효과]
extends Area2D
class_name ZoneEffect


# =============================================================================
# 설정 (initialize() 로 주입)
# =============================================================================

var power         : float  = 5.0
var duration      : float  = 4.0     ## 0 = 영구
var tick_interval : float  = 0.5
var radius        : float  = 80.0
var tags          : Array  = []
var caster        : EntityBase = null

## 장판 위에 있는 엔티티 → 틱 타이머
var _entities_in_zone : Dictionary = {}
var _is_permanent : bool = false


# =============================================================================
# 초기화
# =============================================================================

func initialize(data: Dictionary) -> void:
	power         = data.get("power",          power)
	tick_interval = data.get("tick_interval",  tick_interval)
	radius        = data.get("radius",         radius)
	tags          = data.get("tags",           tags)
	caster        = data.get("caster",         null)

	## duration: 딕셔너리에 키가 있고 값이 0보다 클 때만 덮어씀
	## EffectSpec.duration 기본값이 0.0 이므로 "미설정"과 "영구" 구분 필요
	var passed_dur : float = data.get("duration", -1.0)
	if passed_dur > 0.0:
		duration = passed_dur
	## passed_dur == 0.0 → EffectSpec 에서 설정 안 함 → export 기본값(duration) 유지
	## passed_dur < 0.0  → 키 자체 없음 → export 기본값 유지

	_is_permanent = (duration <= 0.0)

	## 지속시간이 있으면 타이머로 확실하게 소멸 (_process 대신)
	if not _is_permanent:
		get_tree().create_timer(duration).timeout.connect(queue_free)

	## CollisionShape 반지름 조정
	var shape_node := get_node_or_null("CollisionShape2D")
	if shape_node and shape_node.shape is CircleShape2D:
		(shape_node.shape as CircleShape2D).radius = radius


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


# =============================================================================
# 프레임 처리
# =============================================================================

func _process(delta: float) -> void:
	## 장판 안 엔티티 틱 처리
	var to_remove : Array = []
	for entity in _entities_in_zone:
		if not is_instance_valid(entity) or not entity.is_alive():
			to_remove.append(entity)
			continue

		_entities_in_zone[entity] -= delta
		if _entities_in_zone[entity] <= 0.0:
			_entities_in_zone[entity] = tick_interval
			_apply_tick(entity)

	for e in to_remove:
		_entities_in_zone.erase(e)


func _apply_tick(entity: EntityBase) -> void:
	if power > 0.0:
		entity.take_damage(power, tags, caster)


# =============================================================================
# 진입 / 퇴장
# =============================================================================

func _on_body_entered(body: Node) -> void:
	var entity := body as EntityBase
	if entity == null:
		return
	if not entity.is_in_group(&"enemy") and not entity.is_in_group(&"boss"):
		return
	if not _entities_in_zone.has(entity):
		_entities_in_zone[entity] = 0.0   ## 즉시 첫 틱 실행
		_apply_tick(entity)


func _on_body_exited(body: Node) -> void:
	var entity := body as EntityBase
	if entity:
		_entities_in_zone.erase(entity)


# =============================================================================
# 장판 상태 변환 (속성 반응 시스템 연동 — 7단계에서 확장)
# =============================================================================

## 반응 결과로 장판 타입이 바뀔 때 호출
## 예: 물 장판 + 전기 → 감전 장판으로 변환
func transform_to(new_tags: Array, new_power: float) -> void:
	tags  = new_tags
	power = new_power
