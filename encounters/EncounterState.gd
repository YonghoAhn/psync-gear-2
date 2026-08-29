extends RefCounted
class_name EncounterState

enum Result { RUNNING, CLEARED, FAILED }

var objective: EncounterObjective
var elapsed := 0.0
var result: Result = Result.RUNNING


func initialize(new_objective: EncounterObjective) -> void:
	objective = new_objective
	elapsed = 0.0
	result = Result.RUNNING


func tick(delta: float, player_alive: bool, living_targets: int, special_failed: bool = false) -> Result:
	if result != Result.RUNNING:
		return result
	if not player_alive or special_failed:
		result = Result.FAILED
		return result
	elapsed += delta
	match objective.type:
		EncounterObjective.Type.SURVIVE:
			if elapsed >= objective.time_limit:
				result = Result.CLEARED
		EncounterObjective.Type.DEFEAT_ALL, EncounterObjective.Type.BOSS:
			if living_targets <= 0:
				result = Result.CLEARED
			elif objective.time_limit > 0.0 and elapsed >= objective.time_limit:
				result = Result.FAILED
		EncounterObjective.Type.SPECIAL:
			if living_targets <= 0:
				result = Result.CLEARED
	return result

