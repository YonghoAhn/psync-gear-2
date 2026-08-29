## EnemyBase.gd
## 모든 적의 공통 씬 스크립트.
## EnemyDef 를 주입받아 스탯/AI/드랍을 초기화한다.
## 새 적 추가 시 이 스크립트는 건드리지 않는다.
##
## EnemyBase.tscn 노드 트리:
##   CharacterBody2D     [이름: Enemy, Script: EnemyBase.gd]
##   ├── CombatStatsComponent
##   ├── HealthComponent
##   ├── ManaComponent       (선택 — 없어도 됨)
##   ├── StatusComponent
##   ├── MovementComponent
##   ├── DamageReceiver
##   ├── AbilityAnchor
##   ├── StatusApplier
##   ├── CollisionShape2D
##   ├── Sprite2D
##   ├── HealthBar           (선택 — ProgressBar)
##   └── Hitbox  [Area2D]
##       └── CollisionShape2D
extends EntityBase
class_name EnemyBase


# =============================================================================
# 설정
# =============================================================================

@export var enemy_def : EnemyDef = null   ## 에디터에서 직접 지정하거나 코드로 주입


# =============================================================================
# 컴포넌트 추가 참조
# =============================================================================

@onready var sprite      : Node2D   = $Sprite2D
@onready var health_bar  : Node     = get_node_or_null("HealthBar")
@onready var status_applier : StatusApplier = get_node_or_null("StatusApplier")


# =============================================================================
# 내부 상태
# =============================================================================

var _ai      : EnemyAIBase = null
var _target  : Node2D      = null   ## 추적 대상 (플레이어)

## 접촉 피해용 — Hitbox Area2D 가 플레이어와 겹칠 때
const CONTACT_INTERVAL : float = 0.5
var _contact_timer : float = 0.0


# =============================================================================
# 초기화
# =============================================================================

## SpawnDirector 또는 StageScene 에서 호출
func initialize(def: EnemyDef) -> void:
	enemy_def = def
	if is_node_ready():
		_apply_def()
	## is_node_ready() 가 false 면 _entity_ready() 에서 _apply_def() 호출


func _entity_ready() -> void:
	entity_group = &"enemy"

	if enemy_def:
		_apply_def()

	# 플레이어 탐색
	_target = get_tree().get_first_node_in_group(&"player")

	# Hitbox 접촉 피해 연결
	var hitbox := get_node_or_null("Hitbox")
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)

	# HP 변화 → HealthBar 업데이트
	health.hp_changed.connect(_on_hp_changed)


func _apply_def() -> void:
	if enemy_def == null:
		return

	# 스탯 적용
	stats.apply_base_stats(enemy_def.to_stats_dict(enemy_def.is_named))
	health.setup(stats)

	# 태그 적용
	entity_tags = enemy_def.entity_tags.duplicate()
	if enemy_def.is_named:
		entity_tags.append(&"named")

	# 스프라이트 색깔 (임시)
	if sprite and sprite is Sprite2D:
		(sprite as Sprite2D).modulate = enemy_def.sprite_color

	# StatusApplier 연결
	if status_applier:
		status_applier.setup(status, receiver, stats, movement)

	# AI 생성
	_ai = EnemyAIBase.create(enemy_def, self)


func get_base_stats() -> Dictionary:
	## EntityBase._setup_components() 에서 호출됨
	## enemy_def 가 있으면 _apply_def() 에서 별도로 적용하므로 여기선 빈값 반환
	return {}


# =============================================================================
# 프레임 처리
# =============================================================================

func _physics_process(delta: float) -> void:
	if not is_alive() or _ai == null:
		return

	# 플레이어가 사라졌으면 재탐색
	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group(&"player")

	# AI 틱 → 이동 방향
	var move_dir := _ai.tick(delta, _target)
	movement.set_input_direction(move_dir)

	# 접촉 타이머
	_contact_timer -= delta


# =============================================================================
# 접촉 피해
# =============================================================================

func _on_hitbox_body_entered(body: Node) -> void:
	if not body.is_in_group(&"player"):
		return
	if _contact_timer > 0.0:
		return
	_contact_timer = CONTACT_INTERVAL

	var player := body as PlayerController
	if player:
		player.on_contact_with_enemy(self,
			enemy_def.contact_damage if enemy_def else 5.0)


# =============================================================================
# 사망 처리
# =============================================================================

func _on_entity_died() -> void:
	if enemy_def == null:
		return

	# 경험치 / 재화 드랍 신호 (DropController 가 수신)
	GlobalEventBus.drop_spawned.emit({
		"position" : global_position,
		"exp"      : enemy_def.exp_drop,
		"gold"     : enemy_def.gold_drop,
		"chance"   : enemy_def.drop_chance,
	})


# =============================================================================
# HP 바 업데이트
# =============================================================================

func _on_hp_changed(new_hp: float, max_hp: float) -> void:
	if health_bar and health_bar.has_method("set_value_no_signal"):
		health_bar.max_value = max_hp
		health_bar.value     = new_hp
