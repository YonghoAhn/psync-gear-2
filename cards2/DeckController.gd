## Compatibility facade. New systems should depend on DeckState directly.
extends Node
class_name DeckController

var state := DeckState.new()


func initialize_from_profile(profile: ArchetypeProfile, _seed: int = 0) -> void:
	state.cards = profile.build_starting_deck()


func initialize_from_instances(cards: Array[CardInstance], _seed: int = 0) -> void:
	state.cards = cards.duplicate()


func add_card(card: CardInstance) -> void:
	state.add_card(card)


func remove_card(instance_id: StringName) -> bool:
	return state.remove_card(instance_id)


func get_all_cards() -> Array[CardInstance]:
	return state.cards.duplicate()


func get_type_distribution() -> Dictionary:
	return state.family_counts()


func serialize() -> Dictionary:
	return state.serialize()


func _notify_slot_changed(_slot_index: int, _card: CardInstance) -> void:
	pass

