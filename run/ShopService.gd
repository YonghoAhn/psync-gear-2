extends RefCounted
class_name ShopService

static func purchase(session: RunSession, price: int, grant: Callable) -> bool:
	if session == null or price < 0 or not grant.is_valid() or session.currency < price:
		return false
	if not bool(grant.call()):
		return false
	return session.spend_currency(price)


static func remove_card(session: RunSession, deck: DeckState, instance_id: StringName, price: int) -> bool:
	if session.currency < price:
		return false
	if not deck.remove_card(instance_id):
		return false
	return session.spend_currency(price)

