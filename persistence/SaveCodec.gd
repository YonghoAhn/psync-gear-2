extends RefCounted
class_name SaveCodec

const CURRENT_VERSION := 2

static func encode_run(session: RunSession) -> String:
	return JSON.stringify(session.to_dict())


static func decode_run(text: String) -> RunSession:
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		return null
	return RunSession.from_dict(_migrate_run(data))


static func encode_unlocks(profile: UnlockProfile) -> String:
	return JSON.stringify(profile.to_dict())


static func decode_unlocks(text: String) -> UnlockProfile:
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		return null
	return UnlockProfile.from_dict(data)


static func _migrate_run(data: Dictionary) -> Dictionary:
	if data.has("version"):
		var migrated := data.duplicate(true)
		# Version 2 removes active combo cost rules. ComboState ignores legacy
		# cost_limit fields while preserving card IDs and lane order.
		migrated["version"] = CURRENT_VERSION
		return migrated
	## Legacy GameApp dictionary migration.
	return {
		"version": CURRENT_VERSION,
		"seed": int(data.get("seed", 1)),
		"mode": RunSession.Mode.STANDARD,
		"map_id": String(data.get("map_id", "foundry")),
		"character_id": String(data.get("character_id", "")),
		"starting_family_id": String(data.get("archetype_id", "")),
		"current_node_id": "",
		"visited_node_ids": [],
		"currency": int(data.get("currency", 0)),
		"relic_ids": data.get("relic_ids", []),
		"consumables": {},
		"deck_data": {"cards": data.get("deck_state", [])},
		"cycle_data": {},
		"rng_data": data.get("rng_state", {}),
		"endless_loop": 0,
		"success": bool(data.get("success", false)),
		"ended": data.has("success"),
	}
