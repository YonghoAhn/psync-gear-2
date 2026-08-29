extends Node
class_name CombatStatsComponent

signal stats_changed(stat: StringName)

@export var base_max_hp := 100.0
@export var base_move_speed := 220.0
@export var base_magic_power := 10.0
@export var base_magitech_power := 10.0
@export var base_status_power := 1.0
@export var base_crit_chance := 0.05
@export var base_crit_damage := 2.0
@export var base_attack_speed := 1.0
@export var base_defense := 0.0
@export var base_shield_recovery := 1.0
@export var base_tenacity := 0.0
@export var base_luck := 0.0
@export var base_resist_physical := 0.0
@export var base_resist_magic := 0.0
@export var base_resist_magitech := 0.0

## Legacy optional-resource fields retained for old cards and special characters.
@export var base_max_mp := 0.0
@export var base_mp_regen := 0.0
@export var base_pickup_radius := 60.0

var _modifiers: Array[Dictionary] = []


func add_modifier(source_id: StringName, stat: StringName, type: String, value: float) -> void:
	_modifiers.append({"source_id": source_id, "stat": stat, "type": type, "value": value})
	stats_changed.emit(stat)


func remove_modifiers_by_source(source_id: StringName) -> void:
	var changed: Dictionary = {}
	for modifier in _modifiers:
		if modifier["source_id"] == source_id:
			changed[modifier["stat"]] = true
	_modifiers = _modifiers.filter(func(modifier): return modifier["source_id"] != source_id)
	for stat in changed:
		stats_changed.emit(stat)


func remove_modifier(source_id: StringName, stat: StringName) -> void:
	_modifiers = _modifiers.filter(func(modifier): return not (modifier["source_id"] == source_id and modifier["stat"] == stat))
	stats_changed.emit(stat)


func get_stat(stat: StringName) -> float:
	var base := _get_base(stat)
	var flat_bonus := 0.0
	var percent_bonus := 0.0
	for modifier in _modifiers:
		if modifier["stat"] != stat:
			continue
		if modifier["type"] == "flat":
			flat_bonus += float(modifier["value"])
		elif modifier["type"] == "percent":
			percent_bonus += float(modifier["value"])
	return maxf(0.0, (base + flat_bonus) * (1.0 + percent_bonus / 100.0))


func get_resistance(damage_type: int) -> float:
	match damage_type:
		0: return clampf(get_stat(&"resist_physical"), -1.0, 0.9)
		1: return clampf(get_stat(&"resist_magic"), -1.0, 0.9)
		2: return clampf(get_stat(&"resist_magitech"), -1.0, 0.9)
		_: return 0.0


var max_hp: float:
	get: return get_stat(&"max_hp")
var move_speed: float:
	get: return get_stat(&"move_speed")
var magic_power: float:
	get: return get_stat(&"magic_power")
var magitech_power: float:
	get: return get_stat(&"magitech_power")
var status_power: float:
	get: return get_stat(&"status_power")
var crit_chance: float:
	get: return clampf(get_stat(&"crit_chance"), 0.0, 1.0)
var crit_damage: float:
	get: return maxf(1.0, get_stat(&"crit_damage"))
var crit_multiplier: float:
	get: return crit_damage
var attack_speed: float:
	get: return maxf(0.1, get_stat(&"attack_speed"))
var defense: float:
	get: return get_stat(&"defense")
var shield_recovery: float:
	get: return get_stat(&"shield_recovery")
var tenacity: float:
	get: return clampf(get_stat(&"tenacity"), 0.0, 0.9)
var luck: float:
	get: return get_stat(&"luck")
var max_mp: float:
	get: return get_stat(&"max_mp")
var mp_regen: float:
	get: return get_stat(&"mp_regen")
var pickup_radius: float:
	get: return get_stat(&"pickup_radius")
var attack_power: float:
	get: return magic_power


func _get_base(stat: StringName) -> float:
	match stat:
		&"max_hp": return base_max_hp
		&"move_speed": return base_move_speed
		&"magic_power", &"attack_power": return base_magic_power
		&"magitech_power": return base_magitech_power
		&"status_power": return base_status_power
		&"crit_chance": return base_crit_chance
		&"crit_damage", &"crit_multiplier": return base_crit_damage
		&"attack_speed": return base_attack_speed
		&"defense": return base_defense
		&"shield_recovery": return base_shield_recovery
		&"tenacity": return base_tenacity
		&"luck": return base_luck
		&"resist_physical": return base_resist_physical
		&"resist_magic": return base_resist_magic
		&"resist_magitech": return base_resist_magitech
		&"max_mp": return base_max_mp
		&"mp_regen": return base_mp_regen
		&"pickup_radius": return base_pickup_radius
		_: return 0.0


func apply_base_stats(values: Dictionary) -> void:
	for key in values:
		match StringName(key):
			&"max_hp": base_max_hp = float(values[key])
			&"move_speed": base_move_speed = float(values[key])
			&"magic_power", &"attack_power": base_magic_power = float(values[key])
			&"magitech_power": base_magitech_power = float(values[key])
			&"status_power": base_status_power = float(values[key])
			&"crit_chance": base_crit_chance = float(values[key])
			&"crit_damage", &"crit_multiplier": base_crit_damage = float(values[key])
			&"attack_speed": base_attack_speed = float(values[key])
			&"defense": base_defense = float(values[key])
			&"shield_recovery": base_shield_recovery = float(values[key])
			&"tenacity": base_tenacity = float(values[key])
			&"luck": base_luck = float(values[key])
			&"resist_physical": base_resist_physical = float(values[key])
			&"resist_magic": base_resist_magic = float(values[key])
			&"resist_magitech": base_resist_magitech = float(values[key])
			&"max_mp": base_max_mp = float(values[key])
			&"mp_regen": base_mp_regen = float(values[key])
			&"pickup_radius": base_pickup_radius = float(values[key])
		stats_changed.emit(StringName(key))

