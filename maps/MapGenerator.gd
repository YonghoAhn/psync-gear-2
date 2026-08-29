extends RefCounted
class_name MapGenerator

static func generate(definition: MapDef, rng: RunRng) -> RunMap:
	var run_map := RunMap.new()
	run_map.definition_id = definition.id
	var start := MapNode.new()
	start.id = run_map.start_node_id
	start.type = MapNode.Type.START
	run_map.add_node(start)
	var previous_layer: Array[MapNode] = [start]
	var remaining_slots := definition.max_total_nodes - 2
	for depth in range(1, definition.max_depth):
		if remaining_slots <= 0:
			break
		var count := mini(definition.choices_per_depth, remaining_slots)
		var layer: Array[MapNode] = []
		for index in count:
			var node := MapNode.new()
			node.id = StringName("node_%02d_%02d" % [depth, index])
			node.depth = depth
			# 시작 카드군 선택 직후 자동 진입할 첫 경로는 항상 전투로 보장한다.
			node.type = MapNode.Type.COMBAT if depth == 1 and index == 0 else _choose_type(definition, rng)
			run_map.add_node(node)
			layer.append(node)
			remaining_slots -= 1
		for previous in previous_layer:
			for next in layer:
				previous.next_node_ids.append(next.id)
		previous_layer = layer
	var boss := MapNode.new()
	boss.id = run_map.boss_node_id
	boss.type = MapNode.Type.BOSS
	boss.depth = definition.max_depth
	run_map.add_node(boss)
	for previous in previous_layer:
		previous.next_node_ids.append(boss.id)
	return run_map


static func _choose_type(definition: MapDef, rng: RunRng) -> MapNode.Type:
	var types: Array = definition.node_weights.keys()
	var weights: Array[float] = []
	for type in types:
		weights.append(float(definition.node_weights[type]))
	var selected := rng.weighted_index(&"map", weights)
	return int(types[selected]) as MapNode.Type
