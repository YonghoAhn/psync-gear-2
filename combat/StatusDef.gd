extends Resource
class_name StatusDef

enum Category { DAMAGE, CONTROL, WEAKEN, ACCUMULATION }

@export var id: StringName = &""
@export var category: Category = Category.DAMAGE
@export var base_duration := 1.0
@export var max_stacks := 1
@export var trigger_stacks := 0
@export var tick_interval := 1.0
@export var tick_damage := 0.0
@export var immunity_tag: StringName = &""

