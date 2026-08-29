extends RefCounted
class_name CycleRunner

signal card_executed(card: CardInstance, combo_index: int, card_index: int)
signal combo_changed(combo_index: int)

var _deck: DeckState
var _cycle: CycleState
var _execute: Callable
var _card_indices: Array[int] = []
var _remaining: Array[float] = []
var _cooldown_cards: Array[CardInstance] = []
var _cooldown_durations: Array[float] = []
var _cooldown_card_indices: Array[int] = []
var _active_combo_index := 0
var _active_card_index := 0
var _running := false


func configure(deck: DeckState, cycle: CycleState, execute_callback: Callable) -> bool:
	if not ComboValidator.validate(deck, cycle)["valid"]:
		return false
	_deck = deck
	_cycle = cycle
	_execute = execute_callback
	var lane_count := cycle.combos.size()
	_card_indices.resize(lane_count)
	_remaining.resize(lane_count)
	_cooldown_cards.resize(lane_count)
	_cooldown_durations.resize(lane_count)
	_cooldown_card_indices.resize(lane_count)
	_card_indices.fill(0)
	_remaining.fill(0.0)
	_cooldown_cards.fill(null)
	_cooldown_durations.fill(0.0)
	_cooldown_card_indices.fill(0)
	_active_combo_index = 0
	_active_card_index = 0
	return true


func start() -> void:
	_running = _deck != null and _cycle != null


func stop() -> void:
	_running = false


func tick(delta: float, attack_speed: float = 1.0) -> void:
	if not _running:
		return
	for combo_index in range(_cycle.combos.size()):
		_remaining[combo_index] -= delta
		var lane_safety := 0
		while _remaining[combo_index] <= 0.0 and lane_safety < 32:
			lane_safety += 1
			var combo := _cycle.combos[combo_index]
			if combo.card_instance_ids.is_empty():
				break
			var card_index := _card_indices[combo_index]
			var card := _deck.get_card(combo.card_instance_ids[card_index])
			if card == null:
				stop()
				return
			_active_combo_index = combo_index
			_active_card_index = card_index
			# Each combo is an independent Fire & Forget lane. Only cards inside the same lane wait for one another.
			if _execute.is_valid():
				_execute.call(card)
			card_executed.emit(card, combo_index, card_index)
			var interval := maxf(0.02, card.card_def.execution_interval / maxf(0.1, attack_speed))
			_remaining[combo_index] += interval
			_cooldown_cards[combo_index] = card
			_cooldown_durations[combo_index] = interval
			_cooldown_card_indices[combo_index] = card_index
			_card_indices[combo_index] = (card_index + 1) % combo.card_instance_ids.size()
			if _card_indices[combo_index] == 0:
				combo_changed.emit(combo_index)


func current_position() -> Vector2i:
	return Vector2i(_active_combo_index, _active_card_index)


func cooldown_snapshots() -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	if _cycle == null:
		return snapshots
	for combo_index in range(_cycle.combos.size()):
		var card := _cooldown_cards[combo_index]
		if card == null:
			continue
		var duration := maxf(0.02, _cooldown_durations[combo_index])
		var next_index := _card_indices[combo_index]
		var combo := _cycle.combos[combo_index]
		var next_card := _deck.get_card(combo.card_instance_ids[next_index]) if not combo.card_instance_ids.is_empty() else null
		snapshots.append({
			"card": card,
			"next_card": next_card,
			"remaining": maxf(0.0, _remaining[combo_index]),
			"duration": duration,
			"ratio": clampf(_remaining[combo_index] / duration, 0.0, 1.0),
			"combo_index": combo_index,
			"card_index": _cooldown_card_indices[combo_index],
			"lane_label": lane_label(combo_index),
		})
	return snapshots


func cooldown_snapshot() -> Dictionary:
	var snapshots := cooldown_snapshots()
	if snapshots.is_empty():
		return {}
	for snapshot in snapshots:
		if int(snapshot["combo_index"]) == _active_combo_index:
			return snapshot
	return snapshots[0]

static func lane_label(index: int) -> String:
	var number := index + 1
	var result := ""
	while number > 0:
		number -= 1
		result = String.chr(65 + (number % 26)) + result
		number = int(number / 26)
	return result
