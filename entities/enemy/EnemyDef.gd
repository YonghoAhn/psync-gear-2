## EnemyDef.gd
## 적 한 종류의 정적 데이터.
## EnemyBase 가 이 Resource 를 읽어 스탯/AI/드랍을 초기화한다.
## 새 적 추가 = 새 .tres 파일 생성. 스크립트 추가 없음.
extends Resource
class_name EnemyDef

enum Rank { MOB, NAMED, BOSS }
enum Role { MELEE, RANGED, SUPPORT, SUMMONER, DISRUPTOR, CHARGER, BOMBER, SHIELD }


# =============================================================================
# 식별
# =============================================================================

@export var id           : StringName = &""
@export var display_name : String     = ""
@export var rank: Rank = Rank.MOB
@export var role: Role = Role.MELEE
@export_multiline var description := ""
@export var pattern_names: Array[String] = []
@export_multiline var counterplay := ""
@export_range(1, 10) var spawn_tier := 1
@export var behavior_modules: Array[Resource] = []
@export var status_immunity_tags: Array[StringName] = []


# =============================================================================
# 기본 스탯
# =============================================================================

@export_group("Stats")
@export var base_max_hp      : float = 30.0
@export var base_attack_power: float = 8.0
@export var base_move_speed  : float = 120.0
@export var base_defense     : float = 0.0
@export var contact_damage   : float = 5.0   ## 플레이어 접촉 시 피해량


# =============================================================================
# AI 설정
# =============================================================================

@export_group("AI")
enum AIType {
	APPROACH,    ## 접근형 — 플레이어에게 직진
	RANGED,      ## 원거리형 — 거리 유지 + 투사체 공격
	CIRCLE,      ## 순환형 — 플레이어 주변을 원형으로 선회
}

@export var ai_type            : AIType = AIType.APPROACH
@export var detection_range    : float  = 400.0  ## 이 범위 안에 플레이어가 들어오면 활성화
@export var attack_range       : float  = 250.0  ## 원거리 공격 사거리
@export var attack_interval    : float  = 2.0    ## 공격 간격 (초)
@export var preferred_distance : float  = 200.0  ## 원거리/순환형 유지 거리
@export var circle_speed       : float  = 2.0    ## 순환형 각속도 (rad/초)


# =============================================================================
# 투사체 공격 (RANGED 타입)
# =============================================================================

@export_group("Ranged Attack")
@export_file("*.tscn") var projectile_scene: String = ""
@export var projectile_speed : float = 200.0
@export var projectile_tags  : Array[StringName] = []


# =============================================================================
# 태그 & 네임드
# =============================================================================

@export_group("Tags")
@export var entity_tags : Array[StringName] = []
@export var is_named    : bool = false       ## 네임드면 스탯 배수 적용
@export var named_scale : float = 2.0        ## 네임드 스탯 배율


# =============================================================================
# 드랍 테이블
# =============================================================================

@export_group("Drop")
@export var exp_drop     : float = 10.0
@export var gold_drop    : float = 5.0
@export var drop_chance  : float = 1.0   ## 드랍 확률 (0.0 ~ 1.0)


# =============================================================================
# 비주얼
# =============================================================================

@export_group("Visual")
@export var sprite_color : Color = Color.RED   ## 임시 색깔 (텍스처 없을 때)


# =============================================================================
# 스탯 딕셔너리 변환 (EnemyBase 주입용)
# =============================================================================

func to_stats_dict(named: bool = false) -> Dictionary:
	var scale := named_scale if named else 1.0
	return {
		"max_hp"       : base_max_hp       * scale,
		"attack_power" : base_attack_power * scale,
		"move_speed"   : base_move_speed,
		"defense"      : base_defense,
	}
