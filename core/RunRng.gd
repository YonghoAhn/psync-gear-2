extends RefCounted
class_name RunRng

## Deterministic named random streams. Adding calls to one stream does not perturb others.

var _root_seed: int
var _streams: Dictionary = {}


func _init(root_seed: int = 1) -> void:
	_root_seed = root_seed if root_seed != 0 else 1


func stream(stream_name: StringName) -> RandomNumberGenerator:
	if not _streams.has(stream_name):
		var rng := RandomNumberGenerator.new()
		rng.seed = _derive_seed(stream_name)
		_streams[stream_name] = rng
	return _streams[stream_name]


func randi_range(stream_name: StringName, from: int, to: int) -> int:
	return stream(stream_name).randi_range(from, to)


func randf(stream_name: StringName) -> float:
	return stream(stream_name).randf()


func weighted_index(stream_name: StringName, weights: Array[float]) -> int:
	var total := 0.0
	for weight in weights:
		total += maxf(0.0, weight)
	if total <= 0.0:
		return -1
	var roll := stream(stream_name).randf() * total
	for index in weights.size():
		roll -= maxf(0.0, weights[index])
		if roll <= 0.0:
			return index
	return weights.size() - 1


func snapshot() -> Dictionary:
	var states := {}
	for stream_name in _streams:
		states[String(stream_name)] = (_streams[stream_name] as RandomNumberGenerator).state
	return {"root_seed": _root_seed, "states": states}


func restore(data: Dictionary) -> void:
	_root_seed = int(data.get("root_seed", 1))
	_streams.clear()
	for key in data.get("states", {}):
		var rng := stream(StringName(key))
		rng.state = int(data["states"][key])


func _derive_seed(stream_name: StringName) -> int:
	var hash_value := hash("%s:%s" % [_root_seed, String(stream_name)])
	return absi(hash_value) + 1
