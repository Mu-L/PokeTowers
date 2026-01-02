extends PathFollow2D
class_name BaseEnemy

signal died(enemy: BaseEnemy, killer: BaseTower)

@export var species_id: String = ""

# Stats loaded from species
var max_hp: float = 30.0
var speed: float = 100.0
var reward: int = 15
var pokemon_type: GameManager.PokemonType = GameManager.PokemonType.NORMAL
var catch_rate: float = 0.5

# Defense stats for damage calculation
var defense: int = 10
var spec_defense: int = 10
var enemy_level: int = 1

var hp: float
var catch_attempted: bool = false
var last_attacker: BaseTower = null  # Track who dealt killing blow
var slow_timer: float = 0.0
var slow_amount: float = 1.0
var poison_damage: float = 0.0
var poison_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_bar: ProgressBar = $HPBar
var animated_sprite: AnimatedSprite2D = null

func _ready() -> void:
	load_species_data()
	hp = max_hp
	GameManager.register_enemy()
	update_hp_bar()
	if species_id != "":
		GameManager.mark_seen(species_id)

func load_species_data() -> void:
	if species_id == "":
		return
	var species = GameManager.get_species(species_id)
	if not species:
		return
	max_hp = species.base_hp
	speed = species.base_speed
	reward = species.reward
	pokemon_type = species.pokemon_type
	catch_rate = species.catch_rate

	# Calculate defense stats using Pokemon formula
	# Random IV for enemies (0-15 for simpler enemies)
	var iv_def = randi_range(0, 15)
	var iv_spec_def = randi_range(0, 15)
	defense = calc_stat(species.base_defense, iv_def)
	spec_defense = calc_stat(species.base_spec_defense, iv_spec_def)

	# Set up sprite - animated if sheet exists, static otherwise
	if species.sprite_sheet:
		setup_animated_sprite(species)
	elif species.icon and sprite:
		sprite.texture = species.icon

# Pokemon stat formula: ((base + IV) × 2) × level / 100 + 5
func calc_stat(base: int, iv: int) -> int:
	return int(((base + iv) * 2.0) * enemy_level / 100.0) + 5

func setup_animated_sprite(species: PokemonSpecies) -> void:
	if sprite:
		sprite.visible = false

	animated_sprite = AnimatedSprite2D.new()
	animated_sprite.sprite_frames = create_sprite_frames(species)
	animated_sprite.scale = Vector2(2.0, 2.0)  # Same scale as towers
	add_child(animated_sprite)
	animated_sprite.play("idle")

func create_sprite_frames(species: PokemonSpecies) -> SpriteFrames:
	var frames = SpriteFrames.new()
	frames.remove_animation("default")

	frames.add_animation("idle")
	frames.set_animation_speed("idle", species.anim_fps)
	frames.set_animation_loop("idle", true)

	var sheet = species.sprite_sheet
	var frame_w = species.frame_size.x
	var frame_h = species.frame_size.y
	var cols = species.frame_columns

	for col in cols:
		var atlas = AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(col * frame_w, 0, frame_w, frame_h)
		frames.add_frame("idle", atlas)

	return frames

func _process(delta: float) -> void:
	# Movement
	var current_speed = speed * slow_amount
	progress += current_speed * delta

	# Slow effect decay
	if slow_timer > 0:
		slow_timer -= delta
		if slow_timer <= 0:
			slow_amount = 1.0

	# Poison damage (no number spam for DOT)
	if poison_timer > 0:
		poison_timer -= delta
		take_damage(poison_damage * delta, GameManager.PokemonType.GRASS, false)

	# Auto-catch when low HP
	if is_catchable() and not GameManager.is_caught(species_id):
		catch_attempted = true
		if GameManager.catch_pokemon(self):
			show_catch_effect(true)
		else:
			show_catch_effect(false)

	# Reached end of path
	if progress_ratio >= 1.0:
		reach_end()

func is_catchable() -> bool:
	return hp > 0 and hp < max_hp * 0.25 and not catch_attempted and species_id != ""

func show_catch_effect(success: bool) -> void:
	# Visual feedback for catch attempt
	if success:
		flash_color(Color(1, 0.3, 0.3))  # Red pokeball flash
		# Show "Caught!" text
		var label = DamageNumber.new()
		label.text = "CAUGHT!"
		label.position = global_position + Vector2(-30, -40)
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		get_viewport().add_child(label)
	else:
		# Show "Failed!" text
		var label = DamageNumber.new()
		label.text = "FAILED"
		label.position = global_position + Vector2(-25, -40)
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		get_viewport().add_child(label)

func take_damage(amount: float, attacker_type: GameManager.PokemonType = GameManager.PokemonType.NORMAL, show_number: bool = true, attacker: BaseTower = null) -> void:
	var multiplier = GameManager.get_type_multiplier(attacker_type, pokemon_type)
	var actual_damage = amount * multiplier
	_apply_damage(actual_damage, multiplier, show_number, attacker)

# Take pre-calculated damage (type effectiveness already applied)
func take_calculated_damage(amount: float, type_multiplier: float = 1.0, show_number: bool = true, attacker: BaseTower = null) -> void:
	_apply_damage(amount, type_multiplier, show_number, attacker)

func _apply_damage(actual_damage: float, multiplier: float, show_number: bool, attacker: BaseTower = null) -> void:
	hp -= actual_damage
	if attacker:
		last_attacker = attacker
	update_hp_bar()

	# Floating damage number (skip for small DOT ticks)
	if show_number and actual_damage >= 1.0:
		# Use viewport to stay in correct coordinate space
		DamageNumber.spawn(get_viewport(), global_position + Vector2(0, -20), actual_damage, multiplier)

	# Visual feedback for super effective
	if multiplier > 1.0:
		flash_color(Color.YELLOW)

	if hp <= 0:
		die()

func apply_slow(amount: float, duration: float) -> void:
	slow_amount = min(slow_amount, 1.0 - amount)
	slow_timer = max(slow_timer, duration)

func apply_poison(dps: float, duration: float) -> void:
	poison_damage = dps
	poison_timer = duration

func flash_color(color: Color) -> void:
	var target = animated_sprite if animated_sprite else sprite
	if target:
		var tween = create_tween()
		tween.tween_property(target, "modulate", color, 0.1)
		tween.tween_property(target, "modulate", Color.WHITE, 0.1)

func update_hp_bar() -> void:
	if hp_bar:
		hp_bar.value = (hp / max_hp) * 100

func die() -> void:
	died.emit(self, last_attacker)
	GameManager.unregister_enemy(true, reward)
	queue_free()

func reach_end() -> void:
	GameManager.lose_life()
	GameManager.unregister_enemy(false)
	queue_free()
