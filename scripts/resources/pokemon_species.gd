extends Resource
class_name PokemonSpecies

@export var id: String = ""
@export var display_name: String = ""
@export var pokemon_type: GameManager.PokemonType = GameManager.PokemonType.NORMAL
@export var icon: Texture2D

# Tower stats
@export_group("Tower")
@export var base_damage: float = 10.0
@export var base_range: float = 150.0
@export var base_attack_speed: float = 1.0
@export var tower_scene: PackedScene

# Enemy stats
@export_group("Enemy")
@export var base_hp: float = 30.0
@export var base_speed: float = 100.0
@export var reward: int = 15
@export var enemy_scene: PackedScene

# Evolution
@export_group("Evolution")
@export var evolves_to: String = ""  # species id or empty
@export var evolve_level: int = 0

# Catching
@export_group("Catching")
@export var catch_rate: float = 0.5  # 0.0-1.0, higher = easier

# Animation
@export_group("Animation")
@export var sprite_sheet: Texture2D  # idle/walk spritesheet
@export var frame_size: Vector2i = Vector2i(96, 96)
@export var frame_columns: int = 4
@export var anim_fps: float = 8.0
@export var attack_sheet: Texture2D  # attack spritesheet
@export var attack_frame_size: Vector2i = Vector2i(64, 72)
@export var attack_frame_columns: int = 11

# Base Stats (for damage calculation)
@export_group("Base Stats")
@export var base_phys_attack: int = 50
@export var base_spec_attack: int = 50
@export var base_defense: int = 50
@export var base_spec_defense: int = 50
@export var base_stat_speed: int = 50  # Attack speed stat (not movement)
@export var base_stat_range: int = 50  # Range stat (for IV scaling)

# Learnset: level -> move_id
@export_group("Learnset")
@export var learnset: Dictionary = {}

func get_type_name() -> String:
	match pokemon_type:
		GameManager.PokemonType.FIRE: return "Fire"
		GameManager.PokemonType.WATER: return "Water"
		GameManager.PokemonType.GRASS: return "Grass"
		GameManager.PokemonType.ELECTRIC: return "Electric"
		GameManager.PokemonType.GROUND: return "Ground"
		GameManager.PokemonType.ROCK: return "Rock"
		GameManager.PokemonType.FLYING: return "Flying"
		GameManager.PokemonType.BUG: return "Bug"
		_: return "Normal"

func get_type_color() -> Color:
	match pokemon_type:
		GameManager.PokemonType.FIRE: return Color(1.0, 0.5, 0.2)
		GameManager.PokemonType.WATER: return Color(0.3, 0.6, 1.0)
		GameManager.PokemonType.GRASS: return Color(0.4, 0.8, 0.3)
		GameManager.PokemonType.ELECTRIC: return Color(1.0, 0.9, 0.2)
		GameManager.PokemonType.GROUND: return Color(0.8, 0.6, 0.3)
		GameManager.PokemonType.ROCK: return Color(0.6, 0.5, 0.4)
		GameManager.PokemonType.FLYING: return Color(0.6, 0.7, 1.0)
		GameManager.PokemonType.BUG: return Color(0.6, 0.8, 0.2)
		_: return Color(0.7, 0.7, 0.7)
