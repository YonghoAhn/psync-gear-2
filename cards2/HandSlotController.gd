## Deprecated two-slot facade. Automatic CycleRunner replaced manual hand slots.
extends Node
class_name HandSlotController

signal slot_changed(slot_index: int, card: CardInstance)

var _slots: Array[CardInstance] = [null, null]


func setup(_deck: DeckController) -> void:
	push_warning("HandSlotController is deprecated; configure CycleRunner instead")


func get_slot(slot_index: int) -> CardInstance:
	return _slots[slot_index] if slot_index >= 0 and slot_index < _slots.size() else null


func consume_and_refill(slot_index: int) -> void:
	if slot_index >= 0 and slot_index < _slots.size():
		_slots[slot_index] = null
		slot_changed.emit(slot_index, null)


func reroll() -> void:
	pass

