extends Resource
class_name MapDef

enum ArenaShape { CIRCLE, POLYGON }

@export var id: StringName = &""
@export var display_name := ""
@export var arena_shape: ArenaShape = ArenaShape.CIRCLE
@export_range(3, 30) var max_depth := 6
@export_range(5, 100) var max_total_nodes := 20
@export_range(1, 3) var choices_per_depth := 3
@export var node_weights: Dictionary = {
	MapNode.Type.COMBAT: 5.0,
	MapNode.Type.ELITE: 1.2,
	MapNode.Type.SHOP: 1.0,
	MapNode.Type.REST: 1.0,
	MapNode.Type.EVENT: 1.5,
}
@export var difficulty_base := 1.0

