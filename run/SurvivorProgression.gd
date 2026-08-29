extends RefCounted
class_name SurvivorProgression

var level := 1
var xp := 0.0
var next_xp := threshold_for(1)

static func threshold_for(current_level: int) -> float:
	return ceilf(6.0 * pow(1.35, maxf(0.0, float(current_level - 1))))

func add_xp(amount: float) -> int:
	xp += maxf(0.0, amount)
	var levels_gained := 0
	while xp >= next_xp:
		xp -= next_xp
		level += 1
		levels_gained += 1
		next_xp = threshold_for(level)
	return levels_gained

func ratio() -> float:
	return clampf(xp / maxf(1.0, next_xp), 0.0, 1.0)
