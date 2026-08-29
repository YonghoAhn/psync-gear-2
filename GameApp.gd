## GameApp.gd
## 게임 최상위 상태 머신.
## 씬 전환의 "왜"를 결정하고, 실제 전환은 SceneRouter 에 위임한다.
## RunController 를 통해 현재 런 데이터를 보관한다.
extends Node


# =============================================================================
# 상태 정의
# =============================================================================

enum State {
	NONE,
	MAIN_MENU,
	CHARACTER_SELECT,
	STAGE,
	INTERMISSION,
	SHOP,
	GAME_OVER,
}

var current_state: State = State.NONE

## 현재 진행 중인 런 데이터 (런이 없으면 null)
var run_data: Dictionary = {}


# =============================================================================
# 노드 참조 (Main.tscn 에서 연결)
# =============================================================================

@onready var scene_router: Node = $SceneRouter
@onready var event_bus: Node = $GlobalEventBus  # Autoload 이지만 로컬 참조도 유지


# =============================================================================
# 초기화
# =============================================================================

func _ready() -> void:
	_connect_signals()
	transition_to(State.MAIN_MENU)


func _connect_signals() -> void:
	GlobalEventBus.boss_killed.connect(_on_boss_killed)
	GlobalEventBus.player_died.connect(_on_player_died)
	GlobalEventBus.intermission_exited.connect(_on_intermission_exited)


# =============================================================================
# 상태 전환
# =============================================================================

func transition_to(new_state: State) -> void:
	if new_state == current_state:
		return

	_exit_state(current_state)
	current_state = new_state
	_enter_state(current_state)


func _enter_state(state: State) -> void:
	match state:
		State.MAIN_MENU:
			scene_router.go_to_main_menu()

		State.CHARACTER_SELECT:
			scene_router.go_to_character_select()

		State.STAGE:
			var stage_num: int = run_data.get("current_stage", 1)
			var seed: int     = run_data.get("seed", 0)
			scene_router.go_to_stage(stage_num, seed)

		State.INTERMISSION:
			scene_router.go_to_intermission()

		State.SHOP:
			scene_router.go_to_shop()

		State.GAME_OVER:
			scene_router.go_to_game_over(run_data)


func _exit_state(state: State) -> void:
	# 필요 시 상태 퇴장 처리 (ex. 일시정지 해제, 타이머 정리 등)
	pass


# =============================================================================
# 런 제어 (공개 API)
# =============================================================================

## 새 런을 시작한다.
## character_id: 선택한 캐릭터 ID
## archetype_id: 선택한 아키타입 ID
func start_run(character_id: StringName, archetype_id: StringName) -> void:
	run_data = {
		"seed"            : _generate_seed(),
		"character_id"    : character_id,
		"archetype_id"    : archetype_id,
		"current_stage"   : 1,
		"currency"        : 0,
		"relic_ids"       : [],
		"consumable_ids"  : [],
		"deck_state"      : [],      # CardInstance 직렬화 목록
		"offer_bias"      : {},      # DeckProfileAnalyzer 상태
		"upgrade_policy"  : "merge", # "merge" | "currency"
		"rng_state"       : {},      # SeedManager 에서 관리
	}
	GlobalEventBus.run_started.emit(run_data)
	transition_to(State.STAGE)


## 현재 스테이지를 클리어하고 인터미션으로 진입한다.
func enter_intermission() -> void:
	if current_state != State.STAGE:
		push_warning("GameApp: enter_intermission 는 STAGE 상태에서만 호출 가능")
		return
	transition_to(State.INTERMISSION)


## 인터미션을 마치고 다음 스테이지로 진입한다.
func proceed_to_next_stage() -> void:
	run_data["current_stage"] += 1
	transition_to(State.STAGE)


## 런을 종료한다 (사망 또는 모든 스테이지 클리어).
func end_run(success: bool) -> void:
	run_data["ended_at_stage"] = run_data.get("current_stage", 0)
	run_data["success"]        = success
	GlobalEventBus.run_ended.emit(run_data)
	transition_to(State.GAME_OVER)


# =============================================================================
# 신호 수신
# =============================================================================

func _on_boss_killed(_boss) -> void:
	if current_state == State.STAGE:
		enter_intermission()


func _on_player_died() -> void:
	if current_state == State.STAGE:
		end_run(false)


func _on_intermission_exited() -> void:
	proceed_to_next_stage()


# =============================================================================
# 유틸
# =============================================================================

func _generate_seed() -> int:
	return absi(hash("%s:%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()])) + 1
