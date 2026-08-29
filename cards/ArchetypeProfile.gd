## ArchetypeProfile.gd
## 시작 덱 및 플레이 스타일 정의.
## 캐릭터 선택 화면에서 아키타입을 고르면
## 이 Resource 의 데이터로 초기 덱이 구성된다.
extends Resource
class_name ArchetypeProfile


# =============================================================================
# 식별
# =============================================================================

@export var id           : StringName = &""
@export var display_name : String     = ""
@export var description  : String     = ""
@export var icon         : Texture2D  = null


# =============================================================================
# 시작 카드 목록
# =============================================================================

## 시작 시 덱에 들어갈 CardDef 목록 (순서 무관 — DeckController 가 셔플)
## Array[CardDef] 대신 Array[Resource] 사용 — Godot 에디터 클래스 등록 순서 문제 회피
## 런타임에서 as CardDef 로 캐스팅해 사용
@export var starting_card_defs: Array[Resource] = []

## 시작 카드 수량 오버라이드 (같은 카드를 여러 장 넣고 싶을 때)
## { card_def_id: StringName → count: int }
## 비어있으면 starting_card_defs 각 1장
@export var card_counts: Dictionary = {}


# =============================================================================
# 카드 편향 가중치 초기값
# =============================================================================

## 이 아키타입이 시작부터 선호하는 메인 타입 태그와 가중치
## DeckProfileAnalyzer 가 이 값을 시작 편향으로 사용
## 예: { &"projectile": 1.5, &"zone": 0.8 }
@export var bias_weights: Dictionary = {}


# =============================================================================
# 추천 카드군 태그 (카드 제시 UI 에서 하이라이트 등에 활용)
# =============================================================================

@export var recommended_tags: Array[StringName] = []


# =============================================================================
# 초기 덱 생성
# =============================================================================

## DeckController 초기화 시 호출.
## CardInstance 배열을 반환한다.
func build_starting_deck() -> Array[CardInstance]:
	var deck: Array[CardInstance] = []

	for res in starting_card_defs:
		var def := res as CardDef
		if def == null:
			continue
		var count: int = card_counts.get(def.id, 1)
		for i in count:
			deck.append(CardInstance.create(def, &"start"))

	return deck
