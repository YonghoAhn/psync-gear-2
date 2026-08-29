extends RefCounted
class_name DeckState

signal changed

var cards: Array[CardInstance] = []


func add_card(card: CardInstance) -> bool:
	if card == null or card.card_def == null or get_card(card.instance_id) != null:
		return false
	cards.append(card)
	changed.emit()
	return true


func remove_card(instance_id: StringName) -> bool:
	for index in cards.size():
		if cards[index].instance_id == instance_id:
			if cards[index].undeletable or cards[index].locked:
				return false
			cards.remove_at(index)
			changed.emit()
			return true
	return false


func get_card(instance_id: StringName) -> CardInstance:
	for card in cards:
		if card.instance_id == instance_id:
			return card
	return null


func family_counts() -> Dictionary:
	var counts := {}
	for card in cards:
		if card.family_id != &"":
			counts[card.family_id] = counts.get(card.family_id, 0) + 1
	return counts


func serialize() -> Dictionary:
	var result: Array = []
	for card in cards:
		result.append(card.to_dict())
	return {"cards": result}

