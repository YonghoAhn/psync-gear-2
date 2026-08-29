extends RefCounted
class_name EndlessService

static func can_start(map_id: StringName, unlocks: UnlockProfile) -> bool:
	return unlocks != null and unlocks.is_unlocked("endless_maps", map_id)


static func difficulty_multiplier(loop_index: int) -> float:
	return pow(1.22, maxi(0, loop_index))


static func advance(session: RunSession) -> void:
	session.endless_loop += 1
	session.ended = false
	session.success = false
