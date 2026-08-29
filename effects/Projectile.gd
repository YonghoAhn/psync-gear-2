## Projectile.gd
## 투사체 씬 스크립트.
## EffectExecutor 가 initialize() 로 데이터를 주입한다.
## 씬 구성: Area2D → CollisionShape2D + Sprite2D/GPUParticles2D
##
## Projectile.tscn 노드 트리:
##   Area2D              [이름: Projectile, Script: Projectile.gd]
##   ├── CollisionShape2D [CircleShape2D, 반지름 6]
##   └── Sprite2D         [임시 텍스처]
extends Area2D
class_name Projectile


# =============================================================================
# 설정 (initialize() 로 주입)
# =============================================================================

var direction    : Vector2         = Vector2.RIGHT
var speed        : float           = 400.0
var power        : float           = 10.0
var tags         : Array           = []
var pierce_count : int             = 0          ## 남은 관통 횟수
var caster       : EntityBase      = null
var lifetime     : float           = 3.0        ## 초, 이후 자동 소멸

## 이미 피해를 준 엔티티 목록 (중복 피해 방지)
var _hit_entities : Array          = []


# =============================================================================
# 초기화
# =============================================================================

func initialize(data: Dictionary) -> void:
	direction    = data.get("direction",   direction)
	speed        = data.get("speed",       speed)
	power        = data.get("power",       power)
	tags         = data.get("tags",        tags)
	pierce_count = data.get("pierce",      pierce_count)
	caster       = data.get("caster",      null)
	lifetime     = data.get("lifetime",    lifetime)

	rotation = direction.angle()

	## 타이머로 확실하게 소멸
	get_tree().create_timer(lifetime).timeout.connect(
		func(): if is_instance_valid(self): queue_free())


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


# =============================================================================
# 이동
# =============================================================================

func _process(delta: float) -> void:
	position += direction * speed * delta


# =============================================================================
# 충돌 처리
# =============================================================================

func _on_body_entered(body: Node) -> void:
	_try_hit(body)


func _on_area_entered(area: Node) -> void:
	## Hurtbox Area2D 와 충돌 시 부모 엔티티에 피해
	var parent := area.get_parent()
	if parent:
		_try_hit(parent)


func _try_hit(target: Node) -> void:
	## 시전자 자신은 무시
	if target == caster:
		return

	## 이미 피해를 준 대상은 무시 (관통 중 재충돌 방지)
	if target in _hit_entities:
		return

	## 적 그룹만 피해
	if not target.is_in_group(&"enemy") and not target.is_in_group(&"boss"):
		return

	var entity := target as EntityBase
	if entity == null or not entity.is_alive():
		return

	_hit_entities.append(entity)
	entity.take_damage(power, tags, caster)

	## 관통 처리
	if pierce_count > 0:
		pierce_count -= 1
	else:
		queue_free()
