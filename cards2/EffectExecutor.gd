extends Node
class_name EffectExecutor

var _resolver := TargetResolver.new()
var _projectile_root: Node2D
var _vfx_root: Node2D
var _zone_root: Node2D
var _generation := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_resolver.setup(get_tree())


func setup(projectile_root: Node2D, vfx_root: Node2D, zone_root: Node2D) -> void:
	_projectile_root = projectile_root
	_vfx_root = vfx_root
	_zone_root = zone_root


func set_seed(seed: int) -> void:
	_rng.seed = seed if seed != 0 else 1


func cancel_pending() -> void:
	_generation += 1


func execute_all(specs: Array, caster: EntityBase, extra_context: Dictionary = {}) -> void:
	var execution_generation := _generation
	for resource in specs:
		var spec := resource as EffectSpec
		if spec == null:
			continue
		if spec.delay > 0.0:
			await get_tree().create_timer(spec.delay).timeout
		if execution_generation != _generation or not is_instance_valid(caster):
			return
		_execute_one(spec, caster, extra_context)


func _execute_one(spec: EffectSpec, caster: EntityBase, extra_context: Dictionary) -> void:
	var target_data: Dictionary = _resolver.resolve(spec.target_spec, caster)
	if target_data.is_empty():
		return
	var critical := bool(extra_context.get("critical", _rng.randf() < caster.stats.crit_chance))
	var context := DamageContext.create(spec.power, 0.1, _damage_type(spec.tags))
	context.attacker_stats = caster.stats
	context.critical = critical
	context.critical_multiplier = caster.stats.crit_damage
	context.source = caster
	context.tags = spec.tags.duplicate()
	match spec.type:
		EffectSpec.Type.PROJECTILE:
			_spawn_projectile(spec, caster, target_data, DamagePipeline.calculate(context, null))
		EffectSpec.Type.AREA_DAMAGE, EffectSpec.Type.MELEE_DAMAGE:
			for target in target_data["entities"]:
				(target as EntityBase).receiver.receive_context(context)
		EffectSpec.Type.APPLY_STATUS:
			for target in target_data["entities"]:
				(target as EntityBase).status.add_status(spec.status_id, spec.status_stacks, spec.duration)
		EffectSpec.Type.REMOVE_STATUS:
			for target in target_data["entities"]:
				(target as EntityBase).status.clear_status(spec.status_id)
		EffectSpec.Type.RESTORE_HP:
			for target in target_data["entities"]:
				(target as EntityBase).health.heal(spec.power)
		EffectSpec.Type.RESTORE_MP:
			if caster.mana: caster.mana.restore(spec.power)
		EffectSpec.Type.GRANT_SHIELD:
			for target in target_data["entities"]:
				(target as EntityBase).health.add_shield(spec.power)
		EffectSpec.Type.KNOCKBACK:
			for target in target_data["entities"]:
				var entity := target as EntityBase
				entity.movement.apply_knockback((entity.global_position - caster.global_position).normalized() * spec.knockback_force)
		EffectSpec.Type.SPAWN_ZONE, EffectSpec.Type.SPAWN_INSTALLATION, EffectSpec.Type.SPAWN_ENTITY:
			_spawn_scene(spec, target_data["positions"], caster)
		EffectSpec.Type.CHAIN_EFFECT:
			execute_all(spec.chained_effects, caster, extra_context)


func _spawn_projectile(spec: EffectSpec, caster: EntityBase, target_data: Dictionary, power: float) -> void:
	var projectile := Projectile.new()
	(_projectile_root if _projectile_root else caster.get_parent()).add_child(projectile)
	projectile.global_position = caster.global_position
	projectile.initialize({"direction": target_data["direction"], "speed": spec.projectile_speed, "power": power, "tags": spec.tags, "pierce": spec.pierce_count, "caster": caster})


func _spawn_scene(spec: EffectSpec, positions: Array, caster: EntityBase) -> void:
	if spec.spawned_scene.is_empty() or not ResourceLoader.exists(spec.spawned_scene):
		return
	var packed := load(spec.spawned_scene) as PackedScene
	for position in positions:
		var instance := packed.instantiate()
		(_zone_root if _zone_root else caster.get_parent()).add_child(instance)
		if instance is Node2D: instance.global_position = position
		if instance.has_method("initialize"):
			instance.initialize({"power": spec.power, "duration": spec.duration, "tick_interval": spec.tick_interval, "radius": spec.radius, "tags": spec.tags, "caster": caster})


func _damage_type(tags: Array[StringName]) -> DamageContext.Type:
	if tags.has(&"pure"): return DamageContext.Type.PURE
	if tags.has(&"magitech"): return DamageContext.Type.MAGITECH
	if tags.has(&"magic") or tags.any(func(tag): return String(tag).begins_with("element_")): return DamageContext.Type.MAGIC
	return DamageContext.Type.PHYSICAL
