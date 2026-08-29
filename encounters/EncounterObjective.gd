extends Resource
class_name EncounterObjective

enum Type { SURVIVE, DEFEAT_ALL, BOSS, SPECIAL }

@export var type: Type = Type.SURVIVE
@export var time_limit := 60.0
@export var special_id: StringName = &""

