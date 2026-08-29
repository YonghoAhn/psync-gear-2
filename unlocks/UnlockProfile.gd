extends RefCounted
class_name UnlockProfile

var version := 1
var unlocked: Dictionary = {
	"characters": {},
	"families": {},
	"maps": {},
	"endless_maps": {},
}
var progress: Dictionary = {
	"clears": {},
	"family_clears": {},
	"play_style": {},
	"max_difficulty": 0,
	"collection": {},
	"special": {},
}


func unlock(kind: String, content_id: StringName) -> void:
	if not unlocked.has(kind):
		unlocked[kind] = {}
	unlocked[kind][content_id] = true


func is_unlocked(kind: String, content_id: StringName) -> bool:
	return bool(unlocked.get(kind, {}).get(content_id, false))


func evaluate(kind: String, content_id: StringName, condition: UnlockCondition) -> bool:
	if is_unlocked(kind, content_id):
		return true
	if condition == null or not condition.is_met(progress):
		return false
	unlock(kind, content_id)
	return true


func record_clear(map_id: StringName, family_id: StringName, difficulty: int) -> void:
	progress["clears"][map_id] = int(progress["clears"].get(map_id, 0)) + 1
	progress["family_clears"][family_id] = int(progress["family_clears"].get(family_id, 0)) + 1
	progress["max_difficulty"] = maxi(int(progress["max_difficulty"]), difficulty)
	unlock("endless_maps", map_id)


func to_dict() -> Dictionary:
	return {"version": version, "unlocked": unlocked.duplicate(true), "progress": progress.duplicate(true)}


static func from_dict(data: Dictionary) -> UnlockProfile:
	var profile := UnlockProfile.new()
	profile.version = int(data.get("version", 1))
	profile.unlocked = data.get("unlocked", profile.unlocked).duplicate(true)
	profile.progress = data.get("progress", profile.progress).duplicate(true)
	return profile
