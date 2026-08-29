extends RefCounted
class_name BossPatternRunner

signal phase_changed(index: int, phase_id: StringName)
signal pattern_telegraphed(pattern_id: StringName, duration: float)
signal pattern_executed(pattern_id: StringName)

var definition: BossDef
var rng: RunRng
var phases: Array[BossPhaseDef] = []
var phase_index := 0
var _cooldowns: Dictionary = {}
var _active_pattern: BossPatternDef
var _active_remaining := 0.0
var _telegraphing := false


func initialize(boss_def: BossDef, run_rng: RunRng) -> void:
	definition = boss_def
	rng = run_rng
	phases = definition.sorted_phases()
	phase_index = 0
	_cooldowns.clear()
	_active_pattern = null
	_active_remaining = 0.0


func tick(delta: float, health_ratio: float) -> Dictionary:
	_update_phase(health_ratio)
	for pattern_id in _cooldowns.keys():
		_cooldowns[pattern_id] = maxf(0.0, float(_cooldowns[pattern_id]) - delta)
	if _active_pattern:
		_active_remaining -= delta
		if _active_remaining <= 0.0:
			if _telegraphing:
				_telegraphing = false
				_active_remaining = _active_pattern.action_duration
				pattern_executed.emit(_active_pattern.id)
				return {"event": "execute", "pattern": _active_pattern}
			var completed := _active_pattern
			_cooldowns[completed.id] = completed.cooldown
			_active_pattern = null
			return {"event": "complete", "pattern": completed}
		return {}
	var selected := _select_pattern()
	if selected == null:
		return {}
	_active_pattern = selected
	_active_remaining = selected.telegraph_duration
	_telegraphing = true
	pattern_telegraphed.emit(selected.id, selected.telegraph_duration)
	return {"event": "telegraph", "pattern": selected}


func _update_phase(health_ratio: float) -> void:
	if phases.is_empty():
		return
	var next_index := 0
	for index in phases.size():
		if health_ratio <= phases[index].starts_at_health_ratio:
			next_index = index
	if next_index != phase_index:
		phase_index = next_index
		_active_pattern = null
		phase_changed.emit(phase_index, phases[phase_index].id)


func _select_pattern() -> BossPatternDef:
	if phases.is_empty():
		return null
	var candidates: Array[BossPatternDef] = []
	var weights: Array[float] = []
	for resource in phases[phase_index].patterns:
		var pattern := resource as BossPatternDef
		if pattern and float(_cooldowns.get(pattern.id, 0.0)) <= 0.0:
			candidates.append(pattern)
			weights.append(pattern.weight)
	var index := rng.weighted_index(&"boss_pattern", weights)
	return candidates[index] if index >= 0 else null
