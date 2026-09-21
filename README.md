# Carbo

**Godot 4.5 / GDScript real-time action deckbuilder vertical slice.**

Godot 4.5 기반의 실시간 액션 덱빌더 수직 슬라이스입니다. 덱의 모든 카드를 최대 3개 콤보 레인에 배치하며, 각 콤보는 내부 카드 순서를 유지한 채 서로 독립적으로 병렬 반복됩니다.

## 기술 스택

- Godot 4.5
- GDScript
- 데이터 기반 카드 / 적 / 노드 구성
- headless unit / integration tests

## 실행

Godot 4.5 이상에서 `project.godot`을 열거나 다음 명령으로 실행합니다.

```powershell
Godot_v4.5.1-stable_win64_console.exe --path .
```

## 조작

- WASD: 이동
- 마우스: 조준
- 좌클릭: 조준 방향 대시 및 짧은 무적
- 우클릭: 선택된 소모품 사용
- 휠: 회복 드링크 / 철벽 토닉 / 가속 엘릭서 선택

메인 메뉴에서 같은 캐릭터·카드군 시스템을 사용하는 두 흐름을 선택할 수 있습니다.

- `A · 노드 런`: 기존 웨이브/노드 진행을 그대로 유지합니다. 캐릭터와 시작 카드군을 고르면 기본 콤보로 첫 전투에 바로 진입하고, 이후 노드 진입 전 콤보 슬롯을 편집합니다.
- `B · 무한 생존 실험`: 노드와 제한 시간 없이 난이도와 스폰 밀도가 계속 상승합니다. 적 처치로 XP를 얻어 레벨이 오르면 전투가 완전히 일시정지되고, 카드 또는 유물을 선택한 뒤 그 자리에서 A/B/C 콤보 배치 변경과 카드 삭제를 할 수 있습니다.

두 방식 모두 카드를 드래그해 A/B/C 슬롯 사이로 옮기거나 같은 슬롯 안에서 순서를 바꿀 수 있습니다.

전투 카메라는 플레이어를 부드럽게 추적합니다. 적은 등장 위치에 1초 동안 `WARNING` 마커를 표시한 뒤 실제로 생성됩니다.

전투 HUD는 상단 유물 슬롯, 우측 소모품 3칸, 하단 A/B/C 병렬 콤보 레일로 구성됩니다. 각 콤보 슬롯은 현재 카드와 다음 카드를 표시합니다. 슬롯 내부는 카드 쿨다운에 따라 아래에서 위로 차오르고, 외곽선은 현재 카드 순번/콤보 총 카드 수를 나타냅니다.

## 검증

```powershell
Godot_v4.5.1-stable_win64_console.exe --headless --path . --script res://tests/test_runner.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . --script res://tests/integration_runner.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . --script res://tests/survivor_integration_runner.gd
```

## 구현 범위

- seed 기반 노드 맵과 최대 3개 다음 노드
- 전투, 엘리트, 상점, 휴식, 이벤트, 보스 노드
- 일반형/기믹형 캐릭터와 시작 카드군 제한
- 모든 카드 1회 배치 및 콤보 코스트 검증
- A/B/C 병렬 자동 콤보 레인, 카드군 시너지와 세트 단계
- 잡몹 5역할과 조립형 보스 패턴 데이터
- 카드 보상 가중치, 강화, 제거, 해금과 무한 모드
- 시작 UI, 전투 HUD, 결과 화면

상세 재작업 근거와 subtask는 `REWORK_PLAN.md`에 기록되어 있습니다.

## 상태

현재 저장소는 플레이 가능한 수직 슬라이스와 시스템 재작업 결과를 보존한 프로젝트 스냅샷입니다. 구현 범위와 남은 작업은 `IMPLEMENTATION_STATUS.md`, `REWORK_PLAN.md`, `UI_REWORK_EXECUTION_PLAN.md`에서 확인할 수 있습니다.
