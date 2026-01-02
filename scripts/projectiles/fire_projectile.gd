extends BaseProjectile
class_name FireProjectile

var aoe_radius: float = 60.0

func _ready() -> void:
	super._ready()
	pokemon_type = GameManager.PokemonType.FIRE

func hit_enemy(enemy: BaseEnemy) -> void:
	# AoE damage at impact location
	var hit_pos = enemy.global_position
	create_impact_effect(hit_pos)

	# Find all enemies in AoE
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = aoe_radius
	query.shape = circle
	query.transform = Transform2D(0, hit_pos)
	query.collision_mask = 2  # Enemy layer

	var results = space.intersect_shape(query)
	for result in results:
		var collider = result.collider
		if collider is Area2D:
			var e = collider.get_parent()
			if e is BaseEnemy:
				var dist = e.global_position.distance_to(hit_pos)
				var damage_mult = 1.0 - (dist / aoe_radius) * 0.5
				if is_precalculated:
					e.take_calculated_damage(damage * damage_mult, type_multiplier, true, owner_tower)
				else:
					e.take_damage(damage * damage_mult, pokemon_type, true, owner_tower)

func create_impact_effect(pos: Vector2) -> void:
	# Explosion circle
	var circle = Polygon2D.new()
	var points: PackedVector2Array = []
	for i in 24:
		var angle = i * TAU / 24
		points.append(Vector2(cos(angle), sin(angle)) * aoe_radius)
	circle.polygon = points
	circle.color = Color(1.0, 0.5, 0.0, 0.6)
	circle.global_position = pos
	get_viewport().add_child(circle)

	# Use get_tree().create_tween() so tween survives projectile being freed
	var tween = get_tree().create_tween()
	tween.tween_property(circle, "scale", Vector2(1.2, 1.2), 0.1)
	tween.parallel().tween_property(circle, "modulate:a", 0.0, 0.3)
	tween.tween_callback(circle.queue_free)

	# Fire particles
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.amount = 12
	particles.lifetime = 0.5
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.gravity = Vector2(0, -50)
	particles.color = Color(1.0, 0.4, 0.1)
	particles.global_position = pos
	get_viewport().add_child(particles)

	get_tree().create_timer(1.0).timeout.connect(particles.queue_free)
