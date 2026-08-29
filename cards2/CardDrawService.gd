## Legacy draw-pile service kept for save migration. New gameplay uses DeckState + CycleState.
extends RefCounted
class_name CardDrawService

var draw_pile: Array[CardInstance] = []
var used_pile: Array[CardInstance] = []
var _rng := RandomNumberGenerator.new()


func initialize(cards: Array[CardInstance], seed: int = 0) -> void:
	draw_pile = cards.duplicate()
	used_pile.clear()
	_rng.seed = seed if seed != 0 else 1
	_shuffle(draw_pile)


func draw_one() -> CardInstance:
	if draw_pile.is_empty():
		draw_pile = used_pile.duplicate()
		used_pile.clear()
		_shuffle(draw_pile)
	if draw_pile.is_empty():
		return null
	var card: CardInstance = draw_pile.pop_front()
	return card


func discard(card: CardInstance) -> void:
	if card: used_pile.append(card)


func send_to_used(card: CardInstance) -> void:
	discard(card)


func total_count() -> int:
	return draw_pile.size() + used_pile.size()


func get_draw_pile_snapshot() -> Array[CardInstance]:
	return draw_pile.duplicate()


func get_used_pile_snapshot() -> Array[CardInstance]:
	return used_pile.duplicate()


func _shuffle(cards: Array[CardInstance]) -> void:
	for index in range(cards.size() - 1, 0, -1):
		var other := _rng.randi_range(0, index)
		var temporary := cards[index]
		cards[index] = cards[other]
		cards[other] = temporary

