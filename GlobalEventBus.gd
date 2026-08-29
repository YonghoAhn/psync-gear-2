## GlobalEventBus.gd
## Autoload 싱글톤. 게임 전체의 이벤트 버스.
## 유물, 반응 시스템, UI 등 모든 시스템이 이 신호를 통해 통신한다.
## 절대 직접 참조(get_node) 대신 이 버스를 통해 결합도를 낮춘다.
extends Node


# =============================================================================
# COMBAT — 카드 & 덱
# =============================================================================

## 카드가 시전되었을 때
## caster: EntityBase, card: CardInstance, target_data: Dictionary
signal card_cast(caster, card, target_data)

## 카드가 슬롯에 드로우 되었을 때
## slot: int (0 = 좌, 1 = 우), card: CardInstance
signal card_drawn(slot: int, card)

## 덱이 소진되어 used_pile 에서 리셔플 되었을 때
signal deck_reshuffled()

## 리롤이 실행되었을 때
signal hand_rerolled()


# =============================================================================
# COMBAT — 데미지 & 생존
# =============================================================================

## 엔티티가 피해를 받았을 때
## entity: EntityBase, amount: float, tags: Array[StringName], source
signal entity_damaged(entity, amount: float, tags: Array, source)

## 엔티티가 치료받았을 때
signal entity_healed(entity, amount: float)

## 엔티티가 사망했을 때
signal entity_killed(entity, killer)

## 플레이어 전용 피격 (i-frame 등 처리용 별도 신호)
## amount: float, source_tags: Array[StringName]
signal player_hit(amount: float, source_tags: Array)

## 플레이어 사망
signal player_died()


# =============================================================================
# COMBAT — 상태이상
# =============================================================================

## 상태이상이 적용되었을 때
## entity: EntityBase, status_id: StringName, stacks: int
signal status_applied(entity, status_id: StringName, stacks: int)

## 상태이상이 제거되었을 때
signal status_removed(entity, status_id: StringName)

## 상태이상 틱 피해가 발생했을 때
signal status_ticked(entity, status_id: StringName, damage: float)


# =============================================================================
# COMBAT — 속성 반응
# =============================================================================

## 속성 반응이 발동되었을 때
## rule_id: StringName, source: EntityBase, target: EntityBase, position: Vector2
signal reaction_triggered(rule_id: StringName, source, target, position: Vector2)


# =============================================================================
# COMBAT — 적 & 보스
# =============================================================================

## 적이 스폰되었을 때
signal enemy_spawned(enemy)

## 적이 처치되었을 때
signal enemy_killed(enemy, killer)

## 네임드 적이 등장했을 때
signal named_enemy_appeared(enemy)

## 보스가 스폰되었을 때
signal boss_spawned(boss)

## 보스가 처치되었을 때 — 스테이지 클리어 트리거
signal boss_killed(boss)

## 보스 페이즈가 전환되었을 때
## boss: BossBase, phase_index: int
signal boss_phase_changed(boss, phase_index: int)


# =============================================================================
# STAGE — 진행도 & 드랍
# =============================================================================

## 스테이지가 시작되었을 때
## stage_num: int, seed: int
signal stage_started(stage_num: int, seed: int)

## 스테이지가 클리어되었을 때
signal stage_cleared(stage_num: int)

## 경험치 기반 진행도가 변경되었을 때 (UI 업데이트용)
## current: float, maximum: float
signal stage_progress_changed(current: float, maximum: float)

## 웨이브가 시작되었을 때
signal wave_started(wave_index: int)

## 웨이브가 완료되었을 때
signal wave_completed(wave_index: int)

## 드랍 아이템이 생성되었을 때
signal drop_spawned(drop_node)

## 드랍 아이템이 수집되었을 때
signal drop_collected(drop_node, collector)


# =============================================================================
# RUN — 인터미션 & 보상
# =============================================================================

## 인터미션에 진입했을 때
signal intermission_entered(stage_num: int)

## 인터미션에서 나갔을 때 (다음 스테이지 준비)
signal intermission_exited()

## 카드가 덱에 추가되었을 때 (획득, 상점 등 모든 경로)
signal card_acquired(card)

## 카드가 덱에서 제거되었을 때
signal card_removed(card)

## 카드가 강화되었을 때
## card: CardInstance, old_level: int, new_level: int
signal card_upgraded(card, old_level: int, new_level: int)

## 유물이 획득되었을 때
signal relic_acquired(relic_def)

## 소비 아이템이 획득되었을 때
signal consumable_acquired(consumable_def)

## 소비 아이템이 사용되었을 때
signal consumable_used(consumable_def, user)


# =============================================================================
# ECONOMY — 재화
# =============================================================================

## 재화가 변경되었을 때
signal currency_changed(new_amount: int, delta: int)


# =============================================================================
# RUN — 런 전체 흐름
# =============================================================================

## 런이 시작되었을 때
signal run_started(run_data: Dictionary)

## 런이 종료되었을 때 (사망 또는 클리어)
## result: Dictionary { "success": bool, "stage_reached": int, ... }
signal run_ended(result: Dictionary)


# =============================================================================
# 헬퍼 — 자주 쓰는 발행 함수 (선택적 사용)
# =============================================================================

## 엔티티 피해 발행 단축 함수
func emit_damage(entity, amount: float, tags: Array = [], source = null) -> void:
	entity_damaged.emit(entity, amount, tags, source)


## 상태이상 적용 발행 단축 함수
func emit_status(entity, status_id: StringName, stacks: int = 1) -> void:
	status_applied.emit(entity, status_id, stacks)


## 재화 변경 발행 단축 함수
func emit_currency(new_amount: int, delta: int) -> void:
	currency_changed.emit(new_amount, delta)
