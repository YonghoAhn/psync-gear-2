## ConditionEvaluator.gd
## ConditionSpec 배열을 평가해 모든 조건이 충족되는지 반환한다.
## EffectExecutor 가 각 EffectSpec 실행 전에 이 클래스를 사용한다.
extends RefCounted
class_name ConditionEvaluator


## 모든 조건을 평가한다 (AND).
## context: { "caster", "target", "is_crit", "reaction_id" }
static func evaluate_all(conditions: Array, context: Dictionary) -> bool:
	for cond_res in conditions:
		var cond := cond_res as ConditionSpec
		if cond == null:
			continue
		var result := _evaluate_one(cond, context)
		if cond.negate:
			result = not result
		if not result:
			return false
	return true


static func _evaluate_one(cond: ConditionSpec, ctx: Dictionary) -> bool:
	match cond.type:
		ConditionSpec.Type.ALWAYS:
			return true

		ConditionSpec.Type.HP_BELOW_PERCENT:
			var caster := ctx.get("caster") as EntityBase
			if caster == null:
				return false
			return caster.health.get_hp_ratio() < cond.hp_threshold

		ConditionSpec.Type.HP_ABOVE_PERCENT:
			var caster := ctx.get("caster") as EntityBase
			if caster == null:
				return false
			return caster.health.get_hp_ratio() > cond.hp_threshold

		ConditionSpec.Type.TARGET_HAS_STATUS:
			var target := ctx.get("target") as EntityBase
			if target == null or target.status == null:
				return false
			return target.status.has_status(cond.status_id)

		ConditionSpec.Type.TARGET_IS_BOSS:
			var target := ctx.get("target") as EntityBase
			if target == null:
				return false
			return target.is_in_group(&"boss")

		ConditionSpec.Type.TARGET_HAS_TAG:
			var target := ctx.get("target") as EntityBase
			if target == null:
				return false
			return target.has_tag(cond.tag)

		ConditionSpec.Type.IS_CRIT:
			return ctx.get("is_crit", false)

		ConditionSpec.Type.CASTER_HAS_STATUS:
			var caster := ctx.get("caster") as EntityBase
			if caster == null or caster.status == null:
				return false
			return caster.status.has_status(cond.status_id)

		ConditionSpec.Type.ON_REACTION:
			return ctx.get("reaction_id", &"") == cond.reaction_id

		ConditionSpec.Type.RANDOM_CHANCE:
			return float(ctx.get("random_roll", 0.5)) < cond.chance

	return true
