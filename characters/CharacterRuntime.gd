extends RefCounted
class_name CharacterRuntime

signal trait_event(event_name: StringName, context: Dictionary)

var definition: CharacterDef
var traits: Array[CharacterTrait] = []


func initialize(character_def: CharacterDef, stats: CombatStatsComponent) -> void:
	definition = character_def
	traits.clear()
	stats.apply_base_stats(definition.to_stats_dict())
	for resource in definition.traits:
		var character_trait := resource as CharacterTrait
		if character_trait:
			traits.append(character_trait)
			character_trait.apply_stats(stats)


func dispatch(event_name: StringName, context: Dictionary = {}) -> Array[Dictionary]:
	var responses: Array[Dictionary] = []
	for character_trait in traits:
		if character_trait.handles(event_name):
			responses.append({"trait_id": character_trait.id, "rules": character_trait.rule_values.duplicate(true)})
	trait_event.emit(event_name, context)
	return responses


func reward_weight_multiplier(family_id: StringName) -> float:
	var multiplier := 1.0
	for character_trait in traits:
		if character_trait.type == CharacterTrait.Type.CARD_FAMILY and character_trait.family_id == family_id:
			multiplier *= character_trait.family_weight_multiplier
	return multiplier
