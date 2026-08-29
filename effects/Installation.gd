## Installation.gd
## 설치물(포탑, 함정 등) 베이스 스크립트.
## ZoneEffect 와 달리 자체 AI 로 대상을 탐지해 공격하는 구조물이다.
##
## Installation.tscn 노드 트리:
##   Node2D              [이름: Installation, Script: Installation.gd]
##   ├── Sprite2D
##   ├── DetectionArea   [Area2D — 탐지 범위]
##   │   └── CollisionShape2D [CircleShape2D]
##   └── CollisionShape2D    [설치물 본체 충돌]
extends Node2D
class_name Installation


# =============================================================================
# 설정 (initialize() 로 주입)
# =============================================================================

var power          : float     = 10.0
var duration       : float     = 8.0
var tick_interval  : float     = 1.0    ## 공격 간격 (초)
var radius         : float     = 150.0
var tags           : Array     = []
var caster         : EntityBase = null

var _elapsed       : float     = 0.0
var _attack_timer  : float     = 0.0
var _targets_in_range : Array  = []     ## 탐지 범위 내 엔티티


# =============================================================================
# 초기화
# =============================================================================

func initialize(data: Dictionary) -> void:
	power         = data.get("power",          power)
	duration      = data.get("duration",       duration)
	tick_interval = data.get("tick_interval",  tick_interval)
	radius        = data.get("radius",         radius)
	tags          = data.get("tags",           tags)
	caster        = data.get("caster",         null)

	var detection := get_node_or_null("DetectionArea")
	if detection:
		detection.body_entered.connect(_on_target_entered)
		detection.body_exited.connect(_on_target_exited)
		var shape := detection.get_node_or_null("CollisionShape2D")
		if shape and shape.shape is CircleShape2D:
			(shape.shape as CircleShape2D).radius = radius


# =============================================================================
# 프레임 처리
# =============================================================================

func _process(delta: float) -> void:
	_elapsed      += delta
	_attack_timer += delta

	if duration > 0.0 and _elapsed >= duration:
		queue_free()
		return

	if _attack_timer >= tick_interval:
		_attack_timer = 0.0
		_attack_nearest()


func _attack_nearest() -> void:
	## 유효한 대상 중 가장 가까운 적 공격
	var nearest : EntityBase = null
	var best_dist := INF

	for node in _targets_in_range:
		var e := node as EntityBase
		if e == null or not is_instance_valid(e) or not e.is_alive():
			continue
		var d := global_position.distance_squared_to(e.global_position)
		if d < best_dist:
			best_dist = d
			nearest   = e

	if nearest:
		nearest.take_damage(power, tags, caster)
		_play_attack_effect(nearest.global_position)


func _play_attack_effect(_target_pos: Vector2) -> void:
	## 추후 VFX 연결 (빔, 투사체 등)
	pass


# =============================================================================
# 탐지 범위 진입/퇴장
# =============================================================================

func _on_target_entered(body: Node) -> void:
	if body.is_in_group(&"enemy") or body.is_in_group(&"boss"):
		if not body in _targets_in_range:
			_targets_in_range.append(body)


func _on_target_exited(body: Node) -> void:
	_targets_in_range.erase(body)
