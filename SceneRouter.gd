## SceneRouter.gd
## 씬 전환의 "어떻게"를 담당한다.
## GameApp 에서 호출받아 실제 씬 로드/언로드 처리.
## 추후 페이드 트랜지션 애니메이션도 여기에 추가한다.
extends Node


# =============================================================================
# 씬 경로 상수
# =============================================================================

const SCENE_MAIN_MENU        := "res://scenes/ui/MainMenu.tscn"
const SCENE_CHARACTER_SELECT := "res://scenes/ui/CharacterSelect.tscn"
const SCENE_STAGE            := "res://scenes/stage/StageScene.tscn"
const SCENE_INTERMISSION     := "res://scenes/ui/IntermissionScene.tscn"
const SCENE_SHOP             := "res://scenes/ui/ShopScene.tscn"
const SCENE_GAME_OVER        := "res://scenes/ui/GameOver.tscn"


# =============================================================================
# 내부 상태
# =============================================================================

## 현재 로드된 씬 루트 노드
var _current_scene: Node = null

## 씬이 배치될 부모 노드 (Main.tscn 의 SceneContainer)
@onready var _scene_container: Node = get_parent().get_node("SceneContainer")


# =============================================================================
# 공개 전환 API
# =============================================================================

func go_to_main_menu() -> void:
	_load_scene(SCENE_MAIN_MENU)


func go_to_character_select() -> void:
	_load_scene(SCENE_CHARACTER_SELECT)


## stage_num, seed 를 스테이지 씬에 주입한다.
func go_to_stage(stage_num: int, seed: int) -> void:
	var scene_node := _load_scene(SCENE_STAGE)
	if scene_node and scene_node.has_method("initialize"):
		scene_node.initialize(stage_num, seed)


func go_to_intermission() -> void:
	_load_scene(SCENE_INTERMISSION)


func go_to_shop() -> void:
	_load_scene(SCENE_SHOP)


func go_to_game_over(run_data: Dictionary) -> void:
	var scene_node := _load_scene(SCENE_GAME_OVER)
	if scene_node and scene_node.has_method("setup"):
		scene_node.setup(run_data)


# =============================================================================
# 내부 씬 로딩
# =============================================================================

## 씬을 로드하고 컨테이너에 추가한다.
## 기존 씬은 제거한다.
## 반환값: 새로 추가된 씬 루트 노드 (초기화용)
func _load_scene(scene_path: String) -> Node:
	# 기존 씬 제거
	if _current_scene:
		_current_scene.queue_free()
		_current_scene = null

	# 씬 파일 존재 여부 확인 (개발 단계 안전장치)
	if not ResourceLoader.exists(scene_path):
		push_warning("SceneRouter: 씬 파일 없음 → %s (아직 미구현일 수 있음)" % scene_path)
		return null

	# 로드 및 인스턴스화
	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("SceneRouter: 씬 로드 실패 → %s" % scene_path)
		return null

	var instance: Node = packed.instantiate()
	_scene_container.add_child(instance)
	_current_scene = instance

	return instance


# =============================================================================
# 유틸
# =============================================================================

## 현재 씬 루트 반환
func get_current_scene() -> Node:
	return _current_scene
