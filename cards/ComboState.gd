extends RefCounted
class_name ComboState

var id: StringName = &""
var display_name := ""
var card_instance_ids: Array[StringName] = []


static func create(combo_id: StringName, _legacy_cost_limit: int = 0) -> ComboState:
	var combo := ComboState.new()
	combo.id = combo_id
	combo.display_name = String(combo_id)
	return combo


func to_dict() -> Dictionary:
	return {
		"id": String(id),
		"display_name": display_name,
		"card_instance_ids": Array(card_instance_ids),
	}


static func from_dict(data: Dictionary) -> ComboState:
	var combo := ComboState.create(StringName(data.get("id", "")))
	combo.display_name = data.get("display_name", String(combo.id))
	for card_id in data.get("card_instance_ids", []):
		combo.card_instance_ids.append(StringName(card_id))
	return combo