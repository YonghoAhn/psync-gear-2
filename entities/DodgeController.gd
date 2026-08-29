extends Node
class_name DodgeController

signal dodge_started(direction: Vector2)
signal dodge_finished
signal cooldown_changed(remaining: float, maximum: float)

@export var speed := 650.0
@export var duration := 0.16
@export var cooldown := 0.8
@export var invincibility_duration := 0.2

var _body: CharacterBody2D
var _receiver: DamageReceiver
var _direction := Vector2.RIGHT
var _duration_left := 0.0
var _cooldown_left := 0.0


func setup(body: CharacterBody2D, receiver: DamageReceiver) -> void:
	_body = body
	_receiver = receiver


func try_dodge(direction: Vector2) -> bool:
	if _body == null or _cooldown_left > 0.0 or _duration_left > 0.0:
		return false
	_direction = direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	_duration_left = duration
	_cooldown_left = cooldown
	if _receiver:
		_receiver.grant_invincibility(invincibility_duration)
	dodge_started.emit(_direction)
	return true


func _physics_process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left = maxf(0.0, _cooldown_left - delta)
		cooldown_changed.emit(_cooldown_left, cooldown)
	if _duration_left > 0.0 and _body:
		_duration_left -= delta
		_body.velocity = _direction * speed
		_body.move_and_slide()
		if _duration_left <= 0.0:
			dodge_finished.emit()


func is_dodging() -> bool:
	return _duration_left > 0.0


func cooldown_ratio() -> float:
	return _cooldown_left / cooldown if cooldown > 0.0 else 0.0

