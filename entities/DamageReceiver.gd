extends Node
class_name DamageReceiver

signal hit_taken(amount: float, tags: Array)

var _stats: CombatStatsComponent
var _health: HealthComponent
var _status: StatusComponent
var _iframe_remaining := 0.0

var is_invincible: bool:
	get: return _iframe_remaining > 0.0


func setup(stats: CombatStatsComponent, health: HealthComponent, status: StatusComponent) -> void:
	_stats = stats
	_health = health
	_status = status


func receive_context(context: DamageContext) -> float:
	if context == null or context.base_damage <= 0.0 or is_invincible or _health == null:
		return 0.0
	var final_amount := DamagePipeline.calculate(context, _stats)
	if final_amount <= 0.0:
		return 0.0
	var before_total := _health.hp + _health.shield
	_health.apply_damage(final_amount)
	var actual := maxf(0.0, before_total - (_health.hp + _health.shield))
	hit_taken.emit(actual, Array(context.tags))
	GlobalEventBus.entity_damaged.emit(get_parent(), actual, Array(context.tags), context.source)
	if get_parent().is_in_group(&"player"):
		GlobalEventBus.player_hit.emit(actual, Array(context.tags))
	if not context.tags.is_empty() and _status != null:
		_trigger_reaction_check(Array(context.tags), context.source)
	return actual


## Compatibility entrypoint used by projectiles and legacy effects.
func receive_damage(amount: float, tags: Array = [], source: Variant = null, is_crit: Variant = null) -> void:
	var context := DamageContext.create(amount, 0.0, _type_from_tags(tags))
	context.source = source
	context.tags.assign(tags)
	if source is EntityBase:
		context.attacker_stats = (source as EntityBase).stats
	if is_crit == null:
		context.critical = false
	else:
		context.critical = bool(is_crit)
	context.critical_multiplier = context.attacker_stats.crit_damage if context.attacker_stats else 1.0
	receive_context(context)


func grant_invincibility(duration: float) -> void:
	_iframe_remaining = maxf(_iframe_remaining, duration)


func _type_from_tags(tags: Array) -> DamageContext.Type:
	if &"pure" in tags:
		return DamageContext.Type.PURE
	if &"magitech" in tags:
		return DamageContext.Type.MAGITECH
	if &"magic" in tags or &"element_fire" in tags or &"element_water" in tags:
		return DamageContext.Type.MAGIC
	return DamageContext.Type.PHYSICAL


func _trigger_reaction_check(incoming_tags: Array, source: Variant) -> void:
	if Engine.has_singleton("ReactionSystem"):
		Engine.get_singleton("ReactionSystem").check_reaction(get_parent(), incoming_tags, _status.get_all_statuses().keys(), source)


func _process(delta: float) -> void:
	_iframe_remaining = maxf(0.0, _iframe_remaining - delta)
