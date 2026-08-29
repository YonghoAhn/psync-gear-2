extends RefCounted
class_name RunMapController

var run_map: RunMap
var current_node_id: StringName


func initialize(map: RunMap) -> void:
	run_map = map
	current_node_id = map.start_node_id


func available_nodes() -> Array[MapNode]:
	return run_map.available_after(current_node_id)


func select(node_id: StringName) -> bool:
	for node in available_nodes():
		if node.id == node_id:
			current_node_id = node_id
			return true
	return false


func complete_current() -> void:
	var node := run_map.get_node(current_node_id)
	if node:
		node.completed = true

