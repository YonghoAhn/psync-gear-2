extends RefCounted
class_name TestSuite

var failures: Array[String] = []
var assertions := 0


func expect_true(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		failures.append(message)


func expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	assertions += 1
	if actual != expected:
		failures.append("%s (expected=%s actual=%s)" % [message, expected, actual])


func is_success() -> bool:
	return failures.is_empty()

