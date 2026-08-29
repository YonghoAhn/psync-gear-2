extends Resource
class_name EventDef

@export var id: StringName = &""
@export var title := ""
@export_multiline var body := ""
@export var options: Array[Dictionary] = []


func resolve(option_index: int, session: RunSession) -> Dictionary:
	if option_index < 0 or option_index >= options.size():
		return {"success": false}
	var option: Dictionary = options[option_index]
	var cost := int(option.get("currency_cost", 0))
	if cost > 0 and not session.spend_currency(cost):
		return {"success": false, "reason": "currency"}
	var gain := int(option.get("currency_gain", 0))
	if gain:
		session.add_currency(gain)
	return {"success": true, "result": option.get("result", {})}

