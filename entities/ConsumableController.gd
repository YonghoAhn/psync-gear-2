extends Node
class_name ConsumableController

signal selection_changed(index: int, consumable_id: StringName)
signal consumable_used(consumable_id: StringName, remaining: int)

var slots: Array[StringName] = []
var quantities: Dictionary = {}
var selected_index := 0


func add(consumable_id: StringName, amount: int = 1) -> void:
	if not slots.has(consumable_id):
		slots.append(consumable_id)
	quantities[consumable_id] = int(quantities.get(consumable_id, 0)) + amount


func select_delta(delta: int) -> void:
	if slots.is_empty():
		return
	selected_index = posmod(selected_index + delta, slots.size())
	selection_changed.emit(selected_index, slots[selected_index])


func use_selected(user: Node = null) -> bool:
	if slots.is_empty():
		return false
	var consumable_id := slots[selected_index]
	var remaining := int(quantities.get(consumable_id, 0))
	if remaining <= 0:
		return false
	remaining -= 1
	quantities[consumable_id] = remaining
	consumable_used.emit(consumable_id, remaining)
	var bus := get_node_or_null("/root/GlobalEventBus") if is_inside_tree() else null
	if bus:
		bus.consumable_used.emit(consumable_id, user)
	return true
