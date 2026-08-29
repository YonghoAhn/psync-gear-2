extends Resource
class_name EnemyBehaviorDef

enum Action { CHASE, KEEP_DISTANCE, MELEE_ATTACK, PROJECTILE_ATTACK, HEAL_ALLY, BUFF_ALLY, SUMMON, APPLY_DEBUFF, TELEPORT, CHARGE }

@export var id: StringName = &""
@export var action: Action = Action.CHASE
@export var cooldown := 1.0
@export var range := 200.0
@export var power := 1.0
@export var status_id: StringName = &""
@export var summon_enemy_id: StringName = &""
@export var priority := 0

