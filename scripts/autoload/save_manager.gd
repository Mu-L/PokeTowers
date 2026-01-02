extends Node

const SAVE_DIR = "user://saves/"
const SAVE_VERSION = 2  # v2: individual Pokemon with UUIDs
const NUM_SLOTS = 3

var current_slot: int = -1  # -1 = no slot selected

func _ready() -> void:
	# Ensure save directory exists
	DirAccess.make_dir_recursive_absolute(SAVE_DIR.replace("user://", OS.get_user_data_dir() + "/"))

func get_save_path(slot: int) -> String:
	return SAVE_DIR + "slot_%d.json" % slot

func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot))

func get_slot_info(slot: int) -> Dictionary:
	# Returns preview info for slot select screen
	if not slot_exists(slot):
		return {"empty": true}

	var file = FileAccess.open(get_save_path(slot), FileAccess.READ)
	if not file:
		return {"empty": true}

	var data = JSON.parse_string(file.get_as_text())
	if not data:
		return {"empty": true}

	return {
		"empty": false,
		"starter": data.get("starter", ""),
		"pokemon_count": data.get("pokedex", {}).size(),
		"timestamp": data.get("timestamp", 0)
	}

func save_game() -> void:
	if current_slot < 0:
		return

	var data = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"starter": GameManager.starter_pokemon,
		"pokedex": serialize_pokedex(),
		"pokedex_seen": GameManager.pokedex_seen,
		"selected_ball": GameManager.selected_ball,
		"zenny": GameManager.zenny,
		"party_size_limit": GameManager.party_size_limit,
		"species_catch_counts": GameManager.species_catch_counts,
		"party": GameManager.party,  # Now stores UUIDs
		"completed_maps": GameManager.completed_maps,
		"unlocked_generations": GameManager.unlocked_generations
	}
	var file = FileAccess.open(get_save_path(current_slot), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))

func load_slot(slot: int) -> bool:
	var path = get_save_path(slot)
	if not FileAccess.file_exists(path):
		# New slot - reset game state
		reset_game_state()
		current_slot = slot
		return true

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return false

	var data = JSON.parse_string(file.get_as_text())
	if not data:
		return false

	var version = data.get("version", 0)

	# Handle migration from v1 to v2
	if version == 1:
		data = migrate_v1_to_v2(data)
		version = 2

	if version != SAVE_VERSION:
		return false

	# Restore state
	GameManager.starter_pokemon = data.get("starter", "")
	GameManager.selected_ball = data.get("selected_ball", "pokeball")
	GameManager.zenny = data.get("zenny", 0)
	GameManager.party_size_limit = data.get("party_size_limit", 6)

	# Restore species_catch_counts
	GameManager.species_catch_counts.clear()
	var counts = data.get("species_catch_counts", {})
	for species_id in counts:
		GameManager.species_catch_counts[species_id] = counts[species_id]

	deserialize_pokedex(data.get("pokedex", {}))

	# Restore party (UUIDs)
	GameManager.party.clear()
	var party_array = data.get("party", [])
	for uuid in party_array:
		GameManager.party.append(uuid)

	# Handle typed array for pokedex_seen
	GameManager.pokedex_seen.clear()
	var seen_array = data.get("pokedex_seen", [])
	for item in seen_array:
		GameManager.pokedex_seen.append(item)

	# Progression
	GameManager.completed_maps.clear()
	var maps_array = data.get("completed_maps", [])
	for map_id in maps_array:
		GameManager.completed_maps.append(map_id)

	GameManager.unlocked_generations.clear()
	var gens_array = data.get("unlocked_generations", [1])
	for gen in gens_array:
		GameManager.unlocked_generations.append(int(gen))
	# Gen 1 always unlocked
	if 1 not in GameManager.unlocked_generations:
		GameManager.unlocked_generations.append(1)

	current_slot = slot

	# Re-save with new format if migrated
	if version == 1:
		save_game()

	return true

func reset_game_state() -> void:
	GameManager.starter_pokemon = ""
	GameManager.pokedex.clear()
	GameManager.pokedex_seen.clear()
	GameManager.selected_ball = "pokeball"
	GameManager.party.clear()
	GameManager.zenny = 0
	GameManager.party_size_limit = 6
	GameManager.species_catch_counts.clear()
	GameManager.completed_maps.clear()
	GameManager.unlocked_generations = [1]

func delete_slot(slot: int) -> void:
	var path = get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if current_slot == slot:
		reset_game_state()
		current_slot = -1

func serialize_pokedex() -> Dictionary:
	var result = {}
	for uuid in GameManager.pokedex:
		var pokemon: CaughtPokemon = GameManager.pokedex[uuid]
		result[uuid] = pokemon.to_dict()
	return result

func deserialize_pokedex(data: Dictionary) -> void:
	GameManager.pokedex.clear()
	for uuid in data:
		var pokemon = CaughtPokemon.from_dict(data[uuid])
		GameManager.pokedex[uuid] = pokemon

# Migrate v1 saves (species_id keyed) to v2 (uuid keyed)
func migrate_v1_to_v2(data: Dictionary) -> Dictionary:
	var old_pokedex = data.get("pokedex", {})
	var new_pokedex = {}
	var catch_counts = {}
	var starter_uuid = ""

	for species_id in old_pokedex:
		var pokemon_data = old_pokedex[species_id]

		# Generate new UUID and catch_number
		var new_pokemon = CaughtPokemon.from_dict(pokemon_data)
		new_pokemon.catch_number = 1
		catch_counts[species_id] = 1

		# Track starter's new UUID
		if species_id == data.get("starter", ""):
			starter_uuid = new_pokemon.uuid

		new_pokedex[new_pokemon.uuid] = new_pokemon.to_dict()

	data["pokedex"] = new_pokedex
	data["starter"] = starter_uuid
	data["species_catch_counts"] = catch_counts
	data["zenny"] = 0
	data["party_size_limit"] = 6
	data["party"] = []  # Party needs to be re-selected
	data["version"] = 2

	return data

# Export/Import
func export_save() -> String:
	if current_slot < 0:
		return ""
	var path = get_save_path(current_slot)
	if not FileAccess.file_exists(path):
		return ""
	var file = FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file else ""

func import_save(json_text: String) -> bool:
	if current_slot < 0:
		return false

	var data = JSON.parse_string(json_text)
	if not data or not data.has("version"):
		return false

	# Save imported data to current slot
	var file = FileAccess.open(get_save_path(current_slot), FileAccess.WRITE)
	if not file:
		return false
	file.store_string(json_text)

	# Reload slot
	return load_slot(current_slot)

func get_export_path() -> String:
	return OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "/poketowers_save.json"

func export_to_file() -> bool:
	var json = export_save()
	if json == "":
		return false
	var file = FileAccess.open(get_export_path(), FileAccess.WRITE)
	if not file:
		return false
	file.store_string(json)
	return true

func import_from_file() -> bool:
	var path = get_export_path()
	if not FileAccess.file_exists(path):
		return false
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
	return import_save(file.get_as_text())
