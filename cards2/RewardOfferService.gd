extends RefCounted
class_name RewardOfferService

const RARITY_WEIGHTS := {
	CardDef.Rarity.COMMON: 1.0,
	CardDef.Rarity.UNCOMMON: 0.65,
	CardDef.Rarity.RARE: 0.32,
	CardDef.Rarity.HEROIC: 0.14,
	CardDef.Rarity.LEGENDARY: 0.05,
}

static func create_offer(pool: Array[CardDef], deck: DeckState, rng: RunRng, count: int = 3) -> Array[CardDef]:
	var candidates := pool.duplicate()
	var result: Array[CardDef] = []
	var family_counts := deck.family_counts()
	while result.size() < count and not candidates.is_empty():
		var weights: Array[float] = []
		for candidate in candidates:
			var family_bonus := 1.0 + float(family_counts.get(candidate.family_id, 0)) * 0.35
			weights.append(float(RARITY_WEIGHTS.get(candidate.rarity, 0.1)) * family_bonus)
		var selected := rng.weighted_index(&"reward", weights)
		if selected < 0:
			break
		result.append(candidates[selected])
		candidates.remove_at(selected)
	return result

