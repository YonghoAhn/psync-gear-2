extends RefCounted
class_name RestService

enum Action { HEAL, UPGRADE, REMOVE }

static func apply(action: Action, health: HealthComponent, deck: DeckState, card_id: StringName = &"") -> bool:
	match action:
		Action.HEAL:
			if health == null: return false
			health.full_restore()
			return true
		Action.UPGRADE:
			return CardUpgradeService.upgrade(deck.get_card(card_id))
		Action.REMOVE:
			return deck.remove_card(card_id)
	return false

