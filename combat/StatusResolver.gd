extends RefCounted
class_name StatusResolver

static func resolve(definition: StatusDef, requested_stacks: int, target_tags: Array[StringName], tenacity: float) -> Dictionary:
	if definition == null or (definition.immunity_tag != &"" and target_tags.has(definition.immunity_tag)):
		return {"applied": false, "stacks": 0, "duration": 0.0}
	var resistance := clampf(tenacity, 0.0, 0.9)
	var stacks := mini(definition.max_stacks, maxi(1, roundi(float(requested_stacks) * (1.0 - resistance))))
	var duration := definition.base_duration * (1.0 - resistance)
	return {"applied": stacks > 0 and duration > 0.0, "stacks": stacks, "duration": duration}

