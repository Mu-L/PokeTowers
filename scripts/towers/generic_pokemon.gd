extends BaseTower
class_name GenericPokemonTower

# Type-specific parameters
const CHAIN_COUNT: int = 2
const CHAIN_RANGE: float = 80.0
const CHAIN_DMG_MULT: float = 0.6

const AOE_RADIUS: float = 60.0
const ROCK_AOE_RADIUS: float = 50.0

const SLOW_AMOUNT: float = 0.3
const SLOW_DURATION: float = 2.0

const POISON_DPS: float = 5.0
const POISON_DURATION: float = 3.0

const CONE_ANGLE: float = 45.0
const CONE_RANGE: float = 100.0

const MULTI_HIT_COUNT: int = 3
const MULTI_HIT_DMG: float = 0.4

const FLYING_RANGE_MULT: float = 1.5
const FLYING_SPEED_MULT: float = 1.3

# Projectile scenes (preloaded)
var FireProjectileScene = preload("res://scenes/projectiles/fire_projectile.tscn")
var WaterProjectileScene = preload("res://scenes/projectiles/water_projectile.tscn")

var animated_sprite: AnimatedSprite2D = null

func _ready() -> void:
	if caught_pokemon:
		var species = GameManager.get_species(caught_pokemon.species_id)
		if species:
			tower_name = species.display_name
			damage = species.base_damage
			attack_range = species.base_range
			attack_speed = species.base_attack_speed
			pokemon_type = species.pokemon_type

			# Set up sprite - animated if sheet exists, static otherwise
			if species.sprite_sheet:
				setup_animated_sprite(species)
			elif sprite and species.icon:
				sprite.texture = species.icon

			# FLYING type gets range/speed bonus
			if pokemon_type == GameManager.PokemonType.FLYING:
				attack_range *= FLYING_RANGE_MULT
				attack_speed *= FLYING_SPEED_MULT

	super._ready()

func setup_animated_sprite(species: PokemonSpecies) -> void:
	# Hide static sprite
	if sprite:
		sprite.visible = false

	# Create AnimatedSprite2D
	animated_sprite = AnimatedSprite2D.new()
	animated_sprite.sprite_frames = create_sprite_frames(species)
	animated_sprite.scale = Vector2(2.0, 2.0)
	add_child(animated_sprite)
	animated_sprite.play("idle")

func create_sprite_frames(species: PokemonSpecies) -> SpriteFrames:
	var frames = SpriteFrames.new()
	frames.remove_animation("default")

	# Create idle animation from row 0
	frames.add_animation("idle")
	frames.set_animation_speed("idle", species.anim_fps)
	frames.set_animation_loop("idle", true)

	var sheet = species.sprite_sheet
	var frame_w = species.frame_size.x
	var frame_h = species.frame_size.y
	var cols = species.frame_columns

	# Add frames from row 0 (idle)
	for col in cols:
		var atlas = AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(col * frame_w, 0, frame_w, frame_h)
		frames.add_frame("idle", atlas)

	# Add attack animation if exists
	if species.attack_sheet:
		frames.add_animation("attack")
		frames.set_animation_speed("attack", species.anim_fps * 1.5)  # Faster attack
		frames.set_animation_loop("attack", false)

		var atk_w = species.attack_frame_size.x
		var atk_h = species.attack_frame_size.y
		var atk_cols = species.attack_frame_columns

		for col in atk_cols:
			var atlas = AtlasTexture.new()
			atlas.atlas = species.attack_sheet
			atlas.region = Rect2(col * atk_w, 0, atk_w, atk_h)
			frames.add_frame("attack", atlas)

	return frames

func look_at_target() -> void:
	if target:
		var direction = (target.global_position - global_position).normalized()
		var angle = direction.angle()
		if animated_sprite:
			animated_sprite.rotation = angle
		elif sprite:
			sprite.rotation = angle

func play_attack_animation() -> void:
	if animated_sprite and animated_sprite.sprite_frames.has_animation("attack"):
		animated_sprite.play("attack")
		if not animated_sprite.animation_finished.is_connected(_on_attack_finished):
			animated_sprite.animation_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)

func _on_attack_finished() -> void:
	if animated_sprite:
		animated_sprite.play("idle")

# Select best move against target enemy
func select_best_move(enemy: BaseEnemy) -> MoveData:
	if not caught_pokemon or caught_pokemon.known_moves.is_empty():
		return null

	var best_dmg = 0
	var best_move: MoveData = null

	for move_id in caught_pokemon.known_moves:
		var move = GameManager.get_move(move_id)
		if not move or move.category == MoveData.Category.STATUS:
			continue
		var dmg = GameManager.calc_damage(caught_pokemon, move, enemy.defense, enemy.spec_defense, enemy.pokemon_type)
		if dmg > best_dmg:
			best_dmg = dmg
			best_move = move

	return best_move

# Get damage and type multiplier using move-based calculation
func get_move_damage_info(enemy: BaseEnemy) -> Dictionary:
	var move = select_best_move(enemy)
	if move and caught_pokemon:
		var dmg = GameManager.calc_damage(caught_pokemon, move, enemy.defense, enemy.spec_defense, enemy.pokemon_type)
		var mult = GameManager.get_type_multiplier(move.move_type, enemy.pokemon_type)
		return {"damage": dmg, "multiplier": mult, "move": move}
	# Fallback to legacy damage
	return {"damage": get_effective_damage(), "multiplier": 1.0, "move": null}

# Deal damage using moves if available, else legacy
func deal_move_or_legacy_damage(enemy: BaseEnemy, damage_mult: float = 1.0) -> void:
	var info = get_move_damage_info(enemy)
	var final_damage = info.damage * damage_mult
	if info.move:
		deal_calculated_damage(enemy, final_damage, info.multiplier)
	else:
		deal_damage(enemy, final_damage)

func attack(enemy: BaseEnemy) -> void:
	play_attack_animation()
	match pokemon_type:
		GameManager.PokemonType.ELECTRIC:
			attack_chain_lightning(enemy)
		GameManager.PokemonType.FIRE:
			attack_fire_aoe(enemy)
		GameManager.PokemonType.WATER:
			attack_slow(enemy)
		GameManager.PokemonType.GRASS:
			attack_poison(enemy)
		GameManager.PokemonType.ROCK:
			attack_rock_splash(enemy)
		GameManager.PokemonType.GROUND:
			attack_cone(enemy)
		GameManager.PokemonType.BUG:
			attack_multi_hit(enemy)
		_:  # NORMAL, FLYING, etc.
			deal_move_or_legacy_damage(enemy)

# ELECTRIC - Chain lightning bounces between enemies
func attack_chain_lightning(enemy: BaseEnemy) -> void:
	var hit_enemies: Array[BaseEnemy] = [enemy]
	deal_move_or_legacy_damage(enemy)
	create_lightning_effect(global_position, enemy.global_position)

	var current_target = enemy
	for i in CHAIN_COUNT:
		var next_target = find_chain_target(current_target, hit_enemies)
		if next_target:
			deal_move_or_legacy_damage(next_target, CHAIN_DMG_MULT)
			create_lightning_effect(current_target.global_position, next_target.global_position)
			hit_enemies.append(next_target)
			current_target = next_target
		else:
			break

func find_chain_target(from_enemy: BaseEnemy, exclude: Array[BaseEnemy]) -> BaseEnemy:
	var best_target: BaseEnemy = null
	var best_dist: float = CHAIN_RANGE

	for enemy in enemies_in_range:
		if enemy in exclude or not is_instance_valid(enemy):
			continue
		var dist = from_enemy.global_position.distance_to(enemy.global_position)
		if dist < best_dist:
			best_dist = dist
			best_target = enemy

	return best_target

func create_lightning_effect(from: Vector2, to: Vector2) -> void:
	var line = Line2D.new()
	line.width = 3.0
	line.default_color = Color.YELLOW
	line.add_point(from)
	line.add_point(to)
	get_viewport().add_child(line)

	var tween = create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.15)
	tween.tween_callback(line.queue_free)

# FIRE - AOE explosion via projectile
func attack_fire_aoe(enemy: BaseEnemy) -> void:
	var projectile = FireProjectileScene.instantiate()
	projectile.aoe_radius = AOE_RADIUS
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	var info = get_move_damage_info(enemy)
	if info.move:
		projectile.start_precalculated(enemy, info.damage, info.multiplier, self)
	else:
		projectile.start(enemy, info.damage, pokemon_type, self)

# WATER - Slow effect via projectile
func attack_slow(enemy: BaseEnemy) -> void:
	var projectile = WaterProjectileScene.instantiate()
	projectile.slow_amount = SLOW_AMOUNT
	projectile.slow_duration = SLOW_DURATION
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	var info = get_move_damage_info(enemy)
	if info.move:
		projectile.start_precalculated(enemy, info.damage, info.multiplier, self)
	else:
		projectile.start(enemy, info.damage, pokemon_type, self)

# GRASS - Poison damage over time
func attack_poison(enemy: BaseEnemy) -> void:
	deal_move_or_legacy_damage(enemy)
	enemy.apply_poison(POISON_DPS, POISON_DURATION)
	create_poison_effect(enemy)

func create_poison_effect(enemy: BaseEnemy) -> void:
	if enemy.sprite:
		var tween = create_tween()
		tween.tween_property(enemy.sprite, "modulate", Color(0.5, 1.0, 0.5), 0.1)
		tween.tween_interval(0.2)
		tween.tween_property(enemy.sprite, "modulate", Color.WHITE, 0.1)

	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.5
	particles.amount = 6
	particles.lifetime = 0.6
	particles.direction = Vector2(0, -1)
	particles.spread = 60.0
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 40.0
	particles.gravity = Vector2(0, -20)
	particles.color = Color(0.3, 0.8, 0.2, 0.7)
	particles.global_position = enemy.global_position
	get_viewport().add_child(particles)

	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(particles.queue_free)

# ROCK - Splash AOE (direct damage, no projectile)
func attack_rock_splash(enemy: BaseEnemy) -> void:
	deal_move_or_legacy_damage(enemy)
	create_rock_effect(enemy.global_position)

	# Damage nearby enemies
	for other in enemies_in_range:
		if other != enemy and is_instance_valid(other):
			var dist = enemy.global_position.distance_to(other.global_position)
			if dist <= ROCK_AOE_RADIUS:
				deal_move_or_legacy_damage(other, 0.5)

func create_rock_effect(pos: Vector2) -> void:
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.amount = 8
	particles.lifetime = 0.4
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 60.0
	particles.gravity = Vector2(0, 200)
	particles.color = Color(0.6, 0.5, 0.4, 0.9)
	particles.global_position = pos
	get_viewport().add_child(particles)

	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(particles.queue_free)

# GROUND - Cone attack
func attack_cone(enemy: BaseEnemy) -> void:
	var direction = (enemy.global_position - global_position).normalized()
	deal_move_or_legacy_damage(enemy)

	# Damage enemies in cone
	for other in enemies_in_range:
		if other == enemy or not is_instance_valid(other):
			continue

		var to_other = (other.global_position - global_position).normalized()
		var angle = rad_to_deg(direction.angle_to(to_other))
		var dist = global_position.distance_to(other.global_position)

		if abs(angle) <= CONE_ANGLE / 2 and dist <= CONE_RANGE:
			deal_move_or_legacy_damage(other, 0.7)

	create_cone_effect(direction)

func create_cone_effect(direction: Vector2) -> void:
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.6
	particles.amount = 10
	particles.lifetime = 0.3
	particles.direction = direction
	particles.spread = CONE_ANGLE / 2
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 150.0
	particles.gravity = Vector2.ZERO
	particles.color = Color(0.7, 0.5, 0.3, 0.8)
	particles.global_position = global_position
	get_viewport().add_child(particles)

	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(particles.queue_free)

# BUG - Multi-hit rapid attacks
func attack_multi_hit(enemy: BaseEnemy) -> void:
	for i in MULTI_HIT_COUNT:
		if is_instance_valid(enemy):
			deal_move_or_legacy_damage(enemy, MULTI_HIT_DMG)
			create_bug_hit_effect(enemy.global_position, i)

func create_bug_hit_effect(pos: Vector2, _index: int) -> void:
	var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))

	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 3
	particles.lifetime = 0.2
	particles.direction = Vector2(0, -1)
	particles.spread = 45.0
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 40.0
	particles.gravity = Vector2.ZERO
	particles.color = Color(0.4, 0.7, 0.2, 0.8)
	particles.global_position = pos + offset
	get_viewport().add_child(particles)

	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(particles.queue_free)
