extends RefCounted
class_name MapNode

enum Type { START, COMBAT, ELITE, SHOP, REST, EVENT, BOSS }

var id: StringName = &""
var type: Type = Type.COMBAT
var depth := 0
var next_node_ids: Array[StringName] = []
var completed := false


func to_dict() -> Dictionary:
	return {"id": String(id), "type": type, "depth": depth, "next_node_ids": Array(next_node_ids), "completed": completed}

