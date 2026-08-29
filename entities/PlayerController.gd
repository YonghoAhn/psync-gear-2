extends EntityBase
class_name PlayerController

@onready var dodge_controller: DodgeController = get_node_or_null("DodgeController")
@onready var consumable_controller: ConsumableController = get_node_or_null("ConsumableController")

var _aim_direction := Vector2.RIGHT


func _entity_ready() -> void:
	entity_group = &"player"
	add_to_group(&"player")
	if dodge_controller:
		dodge_controller.setup(self, receiver)
	receiver.hit_taken.connect(_on_hit_taken)


func get_base_stats() -> Dictionary:
	return {
		"max_hp": 100.0,
		"move_speed": 220.0,
		"magic_power": 12.0,
		"magitech_power": 10.0,
		"status_power": 1.0,
		"crit_chance": 0.05,
		"crit_damage": 2.0,
		"attack_speed": 1.0,
		"defense": 0.0,
		"shield_recovery": 1.0,
		"tenacity": 0.0,
		"luck": 0.0,
	}


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_aim()
	if event.is_action_pressed(&"dodge") and dodge_controller:
		var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
		dodge_controller.try_dodge(direction if direction != Vector2.ZERO else _aim_direction)
	if event.is_action_pressed(&"use_consumable") and consumable_controller:
		consumable_controller.use_selected(self)
	if event is InputEventMouseButton and event.pressed and consumable_controller:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			consumable_controller.select_delta(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			consumable_controller.select_delta(1)


func _physics_process(_delta: float) -> void:
	_update_aim()
	if dodge_controller and dodge_controller.is_dodging():
		return
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	movement.set_input_direction(direction)


func _update_aim() -> void:
	var delta := get_global_mouse_position() - global_position
	if delta != Vector2.ZERO:
		_aim_direction = delta.normalized()


func get_aim_direction() -> Vector2:
	return _aim_direction


func get_aim_position() -> Vector2:
	return get_global_mouse_position()


func _on_hit_taken(_amount: float, _tags: Array) -> void:
	receiver.grant_invincibility(0.35)


func on_contact_with_enemy(enemy: Node, damage: float, tags: Array = []) -> void:
	take_damage(damage, tags, enemy)
