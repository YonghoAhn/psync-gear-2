extends Resource
class_name UnlockCondition

enum Type { CLEAR, CARD_FAMILY_CLEAR, PLAY_STYLE, DIFFICULTY, COLLECTION, SPECIAL }

@export var type: Type = Type.CLEAR
@export var target_id: StringName = &""
@export var required_value := 1
@export var minimum_difficulty := 0


func is_met(progress: Dictionary) -> bool:
	match type:
		Type.CLEAR:
			return int(progress.get("clears", {}).get(target_id, 0)) >= required_value
		Type.CARD_FAMILY_CLEAR:
			return int(progress.get("family_clears", {}).get(target_id, 0)) >= required_value
		Type.PLAY_STYLE:
			return int(progress.get("play_style", {}).get(target_id, 0)) >= required_value
		Type.DIFFICULTY:
			return int(progress.get("max_difficulty", 0)) >= minimum_difficulty
		Type.COLLECTION:
			return int(progress.get("collection", {}).get(target_id, 0)) >= required_value
		Type.SPECIAL:
			return bool(progress.get("special", {}).get(target_id, false))
	return false

