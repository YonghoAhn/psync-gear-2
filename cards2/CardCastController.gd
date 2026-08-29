## Deprecated manual-cast facade. Cards are executed by CycleRunner.
extends Node
class_name CardCastController

signal cast_started(slot_index: int, card: CardInstance)
signal cast_completed(slot_index: int, card: CardInstance)
signal cast_cancelled(slot_index: int, card: CardInstance)
signal cast_failed_no_mp(slot_index: int, card: CardInstance)


func setup(_hand: HandSlotController, _mana: ManaComponent, _executor: EffectExecutor, _caster: EntityBase, _receiver: DamageReceiver) -> void:
	push_warning("CardCastController is deprecated; use CycleRunner")


func try_cast_slot(_slot_index: int) -> void:
	pass


func on_slot_released(_slot_index: int) -> void:
	pass


func try_reroll() -> void:
	pass


func get_hold_progress() -> float:
	return 0.0
