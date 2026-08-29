extends RefCounted
class_name RunSession

enum Mode { STANDARD, ENDLESS, SURVIVOR_AB }

var version := 2
var seed := 1
var mode: Mode = Mode.STANDARD
var map_id: StringName = &""
var character_id: StringName = &""
var starting_family_id: StringName = &""
var current_node_id: StringName = &""
var visited_node_ids: Array[StringName] = []
var currency := 0
var relic_ids: Array[StringName] = []
var consumables: Dictionary = {}
var deck_data: Dictionary = {}
var cycle_data: Dictionary = {}
var rng_data: Dictionary = {}
var endless_loop := 0
var success := false
var ended := false


static func create(new_seed: int, selected_map: StringName, character: StringName, family: StringName, selected_mode: Mode = Mode.STANDARD) -> RunSession:
	var session := RunSession.new()
	session.seed = new_seed if new_seed != 0 else 1
	session.map_id = selected_map
	session.character_id = character
	session.starting_family_id = family
	session.mode = selected_mode
	return session


func visit_node(node_id: StringName) -> void:
	current_node_id = node_id
	if not visited_node_ids.has(node_id):
		visited_node_ids.append(node_id)


func add_currency(amount: int) -> void:
	currency = maxi(0, currency + amount)


func spend_currency(amount: int) -> bool:
	if amount < 0 or currency < amount:
		return false
	currency -= amount
	return true


func to_dict() -> Dictionary:
	return {
		"version": version,
		"seed": seed,
		"mode": mode,
		"map_id": String(map_id),
		"character_id": String(character_id),
		"starting_family_id": String(starting_family_id),
		"current_node_id": String(current_node_id),
		"visited_node_ids": Array(visited_node_ids),
		"currency": currency,
		"relic_ids": Array(relic_ids),
		"consumables": consumables.duplicate(true),
		"deck_data": deck_data.duplicate(true),
		"cycle_data": cycle_data.duplicate(true),
		"rng_data": rng_data.duplicate(true),
		"endless_loop": endless_loop,
		"success": success,
		"ended": ended,
	}


static func from_dict(data: Dictionary) -> RunSession:
	var session := RunSession.new()
	session.version = int(data.get("version", 1))
	session.seed = int(data.get("seed", 1))
	session.mode = int(data.get("mode", Mode.STANDARD)) as Mode
	session.map_id = StringName(data.get("map_id", ""))
	session.character_id = StringName(data.get("character_id", ""))
	session.starting_family_id = StringName(data.get("starting_family_id", ""))
	session.current_node_id = StringName(data.get("current_node_id", ""))
	for id in data.get("visited_node_ids", []):
		session.visited_node_ids.append(StringName(id))
	session.currency = int(data.get("currency", 0))
	for id in data.get("relic_ids", []):
		session.relic_ids.append(StringName(id))
	session.consumables = data.get("consumables", {}).duplicate(true)
	session.deck_data = data.get("deck_data", {}).duplicate(true)
	session.cycle_data = data.get("cycle_data", {}).duplicate(true)
	session.rng_data = data.get("rng_data", {}).duplicate(true)
	session.endless_loop = int(data.get("endless_loop", 0))
	session.success = bool(data.get("success", false))
	session.ended = bool(data.get("ended", false))
	return session

