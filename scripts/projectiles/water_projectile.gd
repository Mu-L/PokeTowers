extends BaseProjectile
class_name WaterProjectile

var slow_amount: float = 0.3
var slow_duration: float = 2.0

func _ready() -> void:
	super._ready()
	pokemon_type = GameManager.PokemonType.WATER

func hit_enemy(enemy: BaseEnemy) -> void:
	if is_precalculated:
		enemy.take_calculated_damage(damage, type_multiplier, true, owner_tower)
	else:
		enemy.take_damage(damage, pokemon_type, true, owner_tower)
	enemy.apply_slow(slow_amount, slow_duration)
	create_impact_effect(enemy.global_position)

func create_impact_effect(pos: Vector2) -> void:
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.amount = 8
	particles.lifetime = 0.4
	particles.direction = Vector2(0, -1)
	particles.spread = 45.0
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 60.0
	particles.gravity = Vector2(0, 100)
	particles.color = Color(0.3, 0.6, 1.0)
	particles.global_position = pos
	get_viewport().add_child(particles)

	get_tree().create_timer(1.0).timeout.connect(particles.queue_free)
