extends RefCounted
class_name CardUpgradeService

const MAX_LEVEL := 4

static func upgrade(card: CardInstance) -> bool:
	if card == null or card.card_def == null or card.upgrade_level >= MAX_LEVEL:
		return false
	var old_level := card.upgrade_level
	card.upgrade_level += 1
	GlobalEventBus.card_upgraded.emit(card, old_level, card.upgrade_level)
	return true


static func power_multiplier(card: CardInstance) -> float:
	if card == null:
		return 1.0
	return 1.0 + float(card.upgrade_level) * 0.2
