extends RefCounted
class_name RunMap

var definition_id: StringName = &""
var nodes: Dictionary = {}
var start_node_id: StringName = &"start"
var boss_node_id: StringName = &"boss"


func add_node(node: MapNode) -> void:
	nodes[node.id] = node


func get_node(node_id: StringName) -> MapNode:
	return nodes.get(node_id)


func available_after(node_id: StringName) -> Array[MapNode]:
	var source := get_node(node_id)
	var result: Array[MapNode] = []
	if source == null:
		return result
	for next_id in source.next_node_ids:
		var next := get_node(next_id)
		if next:
			result.append(next)
	return result


func validate(max_nodes: int) -> Array[String]:
	var errors: Array[String] = []
	if nodes.size() > max_nodes:
		errors.append("map exceeds max node count")
	if not nodes.has(start_node_id) or not nodes.has(boss_node_id):
		errors.append("map must contain start and boss")
	var reachable := {}
	var frontier: Array[StringName] = [start_node_id]
	while not frontier.is_empty():
		var current: StringName = frontier.pop_front()
		if reachable.has(current):
			continue
		reachable[current] = true
		var node := get_node(current)
		if node:
			frontier.append_array(node.next_node_ids)
	if not reachable.has(boss_node_id):
		errors.append("boss is unreachable")
	return errors
