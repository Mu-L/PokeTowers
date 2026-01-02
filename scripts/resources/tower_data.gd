class_name TowerData extends Resource

@export var id: String = ""
var tower_id: String:  # Alias for compatibility
	get: return id
	set(v): id = v
@export var display_name: String = ""
@export var pokemon_type: GameManager.PokemonType = GameManager.PokemonType.NORMAL
@export var damage: float = 10.0
@export var attack_range: float = 150.0
@export var attack_speed: float = 1.0
@export var icon: Texture2D
@export var scene: PackedScene

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
		GameManager.PokemonType.FIRE: return Color(1.0, 0.4, 0.2)
		GameManager.PokemonType.WATER: return Color(0.3, 0.6, 1.0)
		GameManager.PokemonType.GRASS: return Color(0.3, 0.8, 0.3)
		GameManager.PokemonType.ELECTRIC: return Color(1.0, 0.9, 0.2)
		GameManager.PokemonType.GROUND: return Color(0.8, 0.6, 0.3)
		GameManager.PokemonType.ROCK: return Color(0.7, 0.6, 0.5)
		GameManager.PokemonType.FLYING: return Color(0.6, 0.7, 1.0)
		GameManager.PokemonType.BUG: return Color(0.6, 0.8, 0.2)
		_: return Color.WHITE
