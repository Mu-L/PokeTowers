extends Node

signal lives_changed(new_amount: int)
signal wave_changed(wave_num: int)
signal wave_completed()
signal game_over(won: bool)
signal enemy_killed(enemy: Node2D, reward: int)
signal enemy_selected(enemy: Node2D)
signal pokemon_caught(pokemon: CaughtPokemon)
signal catch_failed(species_id: String)
signal pokemon_evolved(old_species: String, new_species: String)
signal tower_selected(tower: Node2D)
signal tower_deselected()
signal zenny_changed(amount: int)
signal pokemon_placed_signal(uuid: String)

# Game state
var lives: int = 20:
	set(value):
		lives = max(0, value)
		lives_changed.emit(lives)
		if lives <= 0:
			game_over.emit(false)

var current_wave: int = 0
var waves_total: int = 10
var is_wave_active: bool = false
var enemies_alive: int = 0

# Type effectiveness chart
enum PokemonType { NORMAL, FIRE, WATER, GRASS, ELECTRIC, GROUND, ROCK, FLYING, BUG }

var type_chart: Dictionary = {
	PokemonType.FIRE: { PokemonType.GRASS: 2.0, PokemonType.WATER: 0.5, PokemonType.ROCK: 0.5, PokemonType.BUG: 2.0 },
	PokemonType.WATER: { PokemonType.FIRE: 2.0, PokemonType.GRASS: 0.5, PokemonType.GROUND: 2.0 },
	PokemonType.GRASS: { PokemonType.WATER: 2.0, PokemonType.FIRE: 0.5, PokemonType.GROUND: 2.0, PokemonType.BUG: 0.5 },
	PokemonType.ELECTRIC: { PokemonType.WATER: 2.0, PokemonType.GROUND: 0.0 },
	PokemonType.GROUND: { PokemonType.ELECTRIC: 2.0, PokemonType.FIRE: 2.0, PokemonType.ROCK: 2.0 },
	PokemonType.ROCK: { PokemonType.FIRE: 2.0, PokemonType.FLYING: 2.0, PokemonType.BUG: 2.0 },
	PokemonType.FLYING: { PokemonType.BUG: 2.0, PokemonType.GRASS: 2.0 },
}

# Tower placement
var selected_tower_type: String = ""
var is_placing_tower: bool = false
var selected_caught_pokemon: CaughtPokemon = null
var selected_tower: Node2D = null  # Currently selected placed tower

# Map editor
var selected_map_name: String = ""
var selected_map_bg: String = ""
var editing_map_data: MapData = null

# Selected map for gameplay
var selected_map: MapData = null

# Pokemon collection (individual Pokemon)
var pokedex: Dictionary = {}  # uuid -> CaughtPokemon
var pokedex_seen: Array[String] = []
var starter_pokemon: String = ""  # uuid of starter
var party: Array[String] = []  # uuids of party Pokemon
var species_catch_counts: Dictionary = {}  # species_id -> int (for #1, #2 naming)

# Party size system
var party_size_limit: int = 6
const MAX_PARTY_SIZE = 32

# Progression tracking
var completed_maps: Array[String] = []  # map_ids
var unlocked_generations: Array[int] = [1]  # gen numbers

# Meta-currency (earned on run completion)
var zenny: int = 0

# Placement tracking (prevents placing same individual twice)
var placed_pokemon_uuids: Array[String] = []

# Ball settings
var selected_ball: String = "pokeball"
var ball_types: Dictionary = {}  # id -> BallData

# Species registry
var species_registry: Dictionary = {}  # id -> PokemonSpecies

# Move registry
var move_registry: Dictionary = {}  # id -> MoveData

func _ready() -> void:
	load_ball_types()
	load_species_registry()
	load_move_registry()

func load_ball_types() -> void:
	ball_types["pokeball"] = preload("res://resources/balls/pokeball.tres")
	ball_types["greatball"] = preload("res://resources/balls/greatball.tres")
	ball_types["ultraball"] = preload("res://resources/balls/ultraball.tres")

func load_species_registry() -> void:
	# Load all pokemon species from resources/pokemon/
	var dir = DirAccess.open("res://resources/pokemon")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var species = load("res://resources/pokemon/" + file_name) as PokemonSpecies
				if species:
					species_registry[species.id] = species
			file_name = dir.get_next()

func load_move_registry() -> void:
	var dir = DirAccess.open("res://resources/moves")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var move = load("res://resources/moves/" + file_name) as MoveData
				if move:
					move_registry[move.id] = move
			file_name = dir.get_next()

func get_species(species_id: String) -> PokemonSpecies:
	return species_registry.get(species_id)

func get_move(move_id: String) -> MoveData:
	return move_registry.get(move_id)

func get_ball(ball_id: String) -> BallData:
	return ball_types.get(ball_id)

func mark_seen(species_id: String) -> void:
	if species_id not in pokedex_seen:
		pokedex_seen.append(species_id)

# Check if we have at least one of this species
func is_caught(species_id: String) -> bool:
	for pokemon in pokedex.values():
		if pokemon.species_id == species_id:
			return true
	return false

# Get Pokemon by UUID
func get_pokemon_by_uuid(uuid: String) -> CaughtPokemon:
	return pokedex.get(uuid)

# Get all caught Pokemon of a species
func get_all_of_species(species_id: String) -> Array[CaughtPokemon]:
	var result: Array[CaughtPokemon] = []
	for pokemon in pokedex.values():
		if pokemon.species_id == species_id:
			result.append(pokemon)
	return result

# Get next catch number for a species
func get_next_catch_number(species_id: String) -> int:
	if species_id not in species_catch_counts:
		species_catch_counts[species_id] = 0
	species_catch_counts[species_id] += 1
	return species_catch_counts[species_id]

# Check if individual is already placed this game
func is_pokemon_placed(uuid: String) -> bool:
	return uuid in placed_pokemon_uuids

# Mark individual as placed
func mark_pokemon_placed(uuid: String) -> void:
	if uuid not in placed_pokemon_uuids:
		placed_pokemon_uuids.append(uuid)
		pokemon_placed_signal.emit(uuid)

func catch_pokemon(enemy: Node) -> bool:
	var species_id = enemy.species_id if "species_id" in enemy else ""
	if species_id == "":
		return false

	var ball = ball_types.get(selected_ball) as BallData
	if not ball or zenny < ball.cost:
		return false  # Can't afford

	spend_zenny(ball.cost)

	var catch_rate = calculate_catch_rate(enemy, ball)
	if randf() < catch_rate:
		var caught = CaughtPokemon.new()
		caught.species_id = species_id
		caught.catch_number = get_next_catch_number(species_id)
		caught.generate_random_ivs()
		caught.learn_moves_for_level()
		pokedex[caught.uuid] = caught  # Key by uuid
		pokemon_caught.emit(caught)
		SaveManager.save_game()
		return true
	else:
		catch_failed.emit(species_id)
		return false

func calculate_catch_rate(enemy: Node, ball: BallData) -> float:
	var hp = enemy.hp if "hp" in enemy else 0.0
	var max_hp = enemy.max_hp if "max_hp" in enemy else 1.0
	var enemy_catch_rate = enemy.catch_rate if "catch_rate" in enemy else 0.5

	# HP ratio within catchable zone (0-25% HP)
	var hp_ratio = hp / (max_hp * 0.25)
	# Lower HP = better catch rate
	var base = 0.6 * (1.0 - hp_ratio)
	return clamp(base * ball.catch_modifier * enemy_catch_rate, 0.1, 0.95)

func get_type_multiplier(attacker_type: PokemonType, defender_type: PokemonType) -> float:
	if attacker_type in type_chart:
		if defender_type in type_chart[attacker_type]:
			return type_chart[attacker_type][defender_type]
	return 1.0

# Pokemon damage formula
func calc_damage(attacker: CaughtPokemon, move: MoveData, defender_def: int, defender_spec_def: int, defender_type: PokemonType) -> int:
	if not attacker or not move:
		return 0

	var atk_stat: int
	var def_stat: int

	if move.category == MoveData.Category.PHYSICAL:
		atk_stat = attacker.get_phys_attack()
		def_stat = defender_def
	else:
		atk_stat = attacker.get_spec_attack()
		def_stat = defender_spec_def

	# Prevent division by zero
	if def_stat <= 0:
		def_stat = 1

	# Pokemon damage formula
	var damage = ((2.0 * attacker.level / 5.0 + 2.0) * move.power * atk_stat / def_stat) / 50.0 + 2.0

	# Type effectiveness
	damage *= get_type_multiplier(move.move_type, defender_type)

	# STAB (Same Type Attack Bonus)
	var species = get_species(attacker.species_id)
	if species and move.move_type == species.pokemon_type:
		damage *= 1.5

	return int(max(1, damage))

func lose_life(amount: int = 1) -> void:
	lives -= amount

func register_enemy() -> void:
	enemies_alive += 1

func unregister_enemy(was_killed: bool, _reward: int = 0) -> void:
	enemies_alive -= 1
	if enemies_alive <= 0 and is_wave_active:
		is_wave_active = false
		check_wave_complete()

func check_wave_complete() -> void:
	wave_completed.emit()
	if current_wave >= waves_total:
		game_over.emit(true)

func start_wave() -> void:
	if not is_wave_active:
		current_wave += 1
		is_wave_active = true
		wave_changed.emit(current_wave)

func reset_game() -> void:
	lives = 20
	current_wave = 0
	is_wave_active = false
	enemies_alive = 0
	selected_tower_type = ""
	is_placing_tower = false
	placed_pokemon_uuids.clear()

# Zenny functions
func add_zenny(amount: int) -> void:
	zenny += amount
	zenny_changed.emit(zenny)
	SaveManager.save_game()

func spend_zenny(amount: int) -> bool:
	if zenny >= amount:
		zenny -= amount
		zenny_changed.emit(zenny)
		SaveManager.save_game()
		return true
	return false

func get_party_upgrade_cost() -> int:
	if party_size_limit >= MAX_PARTY_SIZE:
		return -1
	return 1000 + (party_size_limit - 5) * 1000  # 2000, 3000, 4000...

func upgrade_party_size() -> bool:
	var cost = get_party_upgrade_cost()
	if cost < 0 or zenny < cost:
		return false
	zenny -= cost
	party_size_limit += 1
	zenny_changed.emit(zenny)
	SaveManager.save_game()
	return true

func select_tower(tower_type: String) -> void:
	selected_tower_type = tower_type
	is_placing_tower = true

func cancel_placement() -> void:
	selected_tower_type = ""
	is_placing_tower = false
	selected_caught_pokemon = null

func select_placed_tower(tower: Node2D) -> void:
	if selected_tower != tower:
		# Deselect previous tower first
		if selected_tower:
			tower_deselected.emit()
		selected_tower = tower
		tower_selected.emit(tower)

func deselect_tower() -> void:
	if selected_tower:
		selected_tower = null
		tower_deselected.emit()

# Progression functions
func is_map_completed(map_id: String) -> bool:
	return map_id in completed_maps

func complete_map(map_id: String) -> void:
	if map_id != "" and map_id not in completed_maps:
		completed_maps.append(map_id)
		SaveManager.save_game()

func is_map_unlocked(campaign: CampaignData, map_index: int) -> bool:
	if map_index == 0:
		return is_generation_unlocked(campaign.generation)
	var prev_map = campaign.maps[map_index - 1]
	return is_map_completed(prev_map.get_id())

func is_generation_unlocked(gen: int) -> bool:
	return gen in unlocked_generations

func unlock_generation(gen: int) -> void:
	if gen not in unlocked_generations:
		unlocked_generations.append(gen)
		SaveManager.save_game()

func get_campaign_progress(campaign: CampaignData) -> int:
	var count = 0
	for m in campaign.maps:
		if is_map_completed(m.get_id()):
			count += 1
	return count
