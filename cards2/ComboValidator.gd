extends RefCounted
class_name ComboValidator

static func validate(deck: DeckState, cycle: CycleState) -> Dictionary:
	var errors: Array[String] = []
	var seen := {}
	var deck_ids := {}
	for card in deck.cards:
		deck_ids[card.instance_id] = card

	if cycle.combos.is_empty():
		errors.append("at least one combo is required")

	for combo in cycle.combos:
		if combo.card_instance_ids.is_empty():
			errors.append("combo %s is empty" % combo.id)
		for card_id in combo.card_instance_ids:
			if not deck_ids.has(card_id):
				errors.append("combo %s references missing card %s" % [combo.id, card_id])
				continue
			if seen.has(card_id):
				errors.append("card %s is assigned more than once" % card_id)
			seen[card_id] = true

	for card_id in deck_ids:
		if not seen.has(card_id):
			errors.append("card %s is not assigned" % card_id)

	return {"valid": errors.is_empty(), "errors": errors}