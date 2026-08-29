extends RefCounted
class_name ContentRegistry

var _content: Dictionary = {}
var errors: Array[String] = []


func register(kind: StringName, content_id: StringName, value: Variant) -> bool:
	if content_id == &"":
		errors.append("%s content has an empty id" % kind)
		return false
	if not _content.has(kind):
		_content[kind] = {}
	if _content[kind].has(content_id):
		errors.append("duplicate %s id: %s" % [kind, content_id])
		return false
	_content[kind][content_id] = value
	return true


func get_content(kind: StringName, content_id: StringName) -> Variant:
	return _content.get(kind, {}).get(content_id)


func get_all(kind: StringName) -> Array:
	return _content.get(kind, {}).values()


func has(kind: StringName, content_id: StringName) -> bool:
	return _content.get(kind, {}).has(content_id)


func validate() -> bool:
	return errors.is_empty()

