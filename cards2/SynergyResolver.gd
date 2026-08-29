extends RefCounted
class_name SynergyResolver

const SET_THRESHOLDS := [3, 5, 7]

static func combo_synergy(combo: ComboState, deck: DeckState) -> Dictionary:
	var families: Dictionary = {}
	var count := 0
	for card_id in combo.card_instance_ids:
		var card := deck.get_card(card_id)
		if card == null or card.card_def.is_neutral or card.card_def.role == CardDef.Role.UTILITY:
			continue
		count += 1
		families[card.family_id] = true
	if families.size() != 1 or count < 2:
		return {"family_id": &"", "tier": 0, "count": count}
	return {"family_id": families.keys()[0], "tier": mini(3, count - 1), "count": count}


static func set_tiers(deck: DeckState) -> Dictionary:
	var result := {}
	for family_id in deck.family_counts():
		var count: int = deck.family_counts()[family_id]
		var tier := 0
		for threshold in SET_THRESHOLDS:
			if count >= threshold:
				tier += 1
		result[family_id] = tier
	return result

