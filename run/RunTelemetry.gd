extends RefCounted
class_name RunTelemetry

var seed := 0
var map_id: StringName = &""
var character_id: StringName = &""
var family_id: StringName = &""
var card_casts: Dictionary = {}
var node_choices: Dictionary = {}
var damage_by_source: Dictionary = {}
var deaths: Dictionary = {}
var events: Array[Dictionary] = []


func begin(session: RunSession) -> void:
	seed = session.seed
	map_id = session.map_id
	character_id = session.character_id
	family_id = session.starting_family_id


func record_card(card_id: StringName) -> void:
	card_casts[card_id] = int(card_casts.get(card_id, 0)) + 1


func record_node(type: MapNode.Type) -> void:
	node_choices[type] = int(node_choices.get(type, 0)) + 1


func record_damage(source_id: StringName, amount: float) -> void:
	damage_by_source[source_id] = float(damage_by_source.get(source_id, 0.0)) + amount


func record_death(reason: StringName) -> void:
	deaths[reason] = int(deaths.get(reason, 0)) + 1


func event(name: StringName, data: Dictionary = {}) -> void:
	events.append({"name": String(name), "data": data.duplicate(true)})


func report() -> Dictionary:
	return {
		"seed": seed,
		"map_id": String(map_id),
		"character_id": String(character_id),
		"family_id": String(family_id),
		"card_casts": card_casts.duplicate(true),
		"node_choices": node_choices.duplicate(true),
		"damage_by_source": damage_by_source.duplicate(true),
		"deaths": deaths.duplicate(true),
		"events": events.duplicate(true),
	}

