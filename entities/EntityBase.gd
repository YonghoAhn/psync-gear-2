## EntityBase.gd
## 플레이어, 적, 보스, 소환물, 설치물의 공통 베이스.
## CharacterBody2D 를 상속하며 모든 컴포넌트를 하나의 인터페이스로 묶는다.
##
## 씬 구성 규칙:
##   EntityBase (CharacterBody2D, 이 스크립트)
##   ├── CombatStatsComponent  [Node]
##   ├── HealthComponent       [Node]
##   ├── ManaComponent         [Node] (적은 선택)
##   ├── StatusComponent       [Node]
##   ├── MovementComponent     [Node]
##   ├── DamageReceiver        [Node]
##   ├── AbilityAnchor         [Node]
##   ├── CollisionShape2D
##   └── Sprite2D / AnimatedSprite2D
extends CharacterBody2D
class_name EntityBase


# =============================================================================
# 컴포넌트 참조
# =============================================================================

@onready var stats    : CombatStatsComponent = $CombatStatsComponent
@onready var health   : HealthComponent      = $HealthComponent
@onready var mana     : ManaComponent        = $ManaComponent          # 없으면 null
@onready var status   : StatusComponent      = $StatusComponent
@onready var movement : MovementComponent    = $MovementComponent
@onready var receiver : DamageReceiver       = $DamageReceiver
@onready var anchor   : AbilityAnchor        = $AbilityAnchor


# =============================================================================
# 태그 (속성 반응, ConditionSpec 판정에 사용)
# =============================================================================

## 이 엔티티의 고유 태그. 씬/EnemyDef 에서 설정.
## 예: [&"boss", &"element_fire", &"named"]
@export var entity_tags: Array[StringName] = []

## 그룹 등록 이름 (Godot 그룹 시스템 활용)
## 예: &"enemy", &"player", &"boss", &"summon"
@export var entity_group: StringName = &""


# =============================================================================
# 초기화
# =============================================================================

func _ready() -> void:
	# 그룹 등록
	if entity_group != &"":
		add_to_group(entity_group)

	# ManaComponent 는 없는 엔티티도 있음
	if mana == null and has_node("ManaComponent"):
		mana = $ManaComponent

	# 컴포넌트 연결
	_setup_components()

	# HealthComponent 사망 신호 연결
	health.died.connect(_on_died)

	# 서브클래스 초기화
	_entity_ready()


func _setup_components() -> void:
	stats.apply_base_stats(get_base_stats())   # 서브클래스에서 오버라이드 가능
	health.setup(stats)
	if mana:
		mana.setup(stats)
	movement.setup(self, stats)
	receiver.setup(stats, health, status)


## 서브클래스에서 오버라이드 — 기본 스탯 딕셔너리 반환.
## EnemyDef 주입 시에는 이 함수를 거치지 않고 직접 apply_base_stats 를 호출한다.
func get_base_stats() -> Dictionary:
	return {}


## 서브클래스에서 오버라이드 — _ready 마지막에 호출되는 훅.
func _entity_ready() -> void:
	pass


# =============================================================================
# 공개 편의 API
# =============================================================================

## 외부에서 이 엔티티에 피해를 입히는 단일 진입점.
func take_damage(amount: float, tags: Array = [], source = null) -> void:
	receiver.receive_damage(amount, tags, source)


## 태그 보유 여부 확인 (entity_tags + status 태그 통합).
func has_tag(tag: StringName) -> bool:
	if entity_tags.has(tag):
		return true
	if status and status.has_status(tag):
		return true
	return false


## 이 엔티티의 전체 태그 (entity_tags + 현재 상태이상 ID) 반환.
func get_all_tags() -> Array[StringName]:
	var combined: Array[StringName] = entity_tags.duplicate()
	if status:
		for sid in status.get_all_statuses():
			combined.append(sid)
	return combined


## 현재 살아있는지.
func is_alive() -> bool:
	return health.is_alive()


# =============================================================================
# 사망 처리
# =============================================================================

func _on_died() -> void:
	GlobalEventBus.entity_killed.emit(self, null)

	# 적 그룹이면 enemy_killed 신호도 발행
	if is_in_group(&"enemy"):
		GlobalEventBus.enemy_killed.emit(self, null)
	elif is_in_group(&"boss"):
		GlobalEventBus.boss_killed.emit(self)
	elif is_in_group(&"player"):
		GlobalEventBus.player_died.emit()

	# 서브클래스 사망 훅
	_on_entity_died()

	queue_free()


## 서브클래스에서 오버라이드 — 사망 시 추가 처리 (드랍, 이펙트 등).
func _on_entity_died() -> void:
	pass
