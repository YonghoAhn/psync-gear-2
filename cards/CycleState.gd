extends RefCounted
class_name CycleState

var combos: Array[ComboState] = []


func to_dict() -> Dictionary:
	var serialized: Array = []
	for combo in combos:
		serialized.append(combo.to_dict())
	return {"combos": serialized}


static func from_dict(data: Dictionary) -> CycleState:
	var cycle := CycleState.new()
	for combo_data in data.get("combos", []):
		cycle.combos.append(ComboState.from_dict(combo_data))
	return cycle

