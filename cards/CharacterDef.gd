extends Resource
class_name CharacterDef

enum Style { GENERAL, GIMMICK }

@export var id: StringName = &""
@export var display_name := ""
@export_multiline var description := ""
@export var icon: Texture2D
@export var style: Style = Style.GENERAL

@export_group("Base Stats")
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

@export_group("Run Rules")
@export var allowed_starting_families: Array[StringName] = []
@export_range(1, 8, 1) var base_combo_slots := 3
@export var traits: Array[Resource] = []
@export var unlock_condition: Resource

@export_group("Dodge")
@export var dodge_speed := 650.0
@export var dodge_duration := 0.16
@export var dodge_cooldown := 0.8
@export var invincibility_duration := 0.2


func allows_family(family_id: StringName) -> bool:
	return allowed_starting_families.has(family_id)


func combo_slot_count(modifier := 0) -> int:
	return maxi(1, base_combo_slots + modifier)


func to_stats_dict() -> Dictionary:
	return {
		"max_hp": base_max_hp,
		"move_speed": base_move_speed,
		"magic_power": base_magic_power,
		"magitech_power": base_magitech_power,
		"status_power": base_status_power,
		"crit_chance": base_crit_chance,
		"crit_damage": base_crit_damage,
		"attack_speed": base_attack_speed,
		"defense": base_defense,
		"shield_recovery": base_shield_recovery,
		"tenacity": base_tenacity,
		"luck": base_luck,
	}

