extends Resource
class_name CaughtPokemon

@export var uuid: String = ""
@export var species_id: String = ""
@export var catch_number: int = 0
@export var nickname: String = ""
@export var level: int = 1
@export var xp: int = 0

# IVs (0-31, random at catch) — like mainline Pokémon games
@export var iv_phys_attack: int = 0
@export var iv_spec_attack: int = 0
@export var iv_defense: int = 0
@export var iv_speed: int = 0
@export var iv_range: int = 0

# Known moves (max 4, stores move IDs)
@export var known_moves: Array[String] = []

# Pending moves waiting for player to choose (not saved)
var pending_moves: Array[String] = []

# IV stat names for display/iteration
const IV_STATS := ["ATK", "SP.ATK", "DEF", "SPD", "RNG"]

func _init() -> void:
	if uuid == "":
		uuid = generate_uuid()

static func generate_uuid() -> String:
	return "%d_%d" % [randi(), Time.get_unix_time_from_system()]

func get_display_name() -> String:
	if nickname != "":
		return nickname
	var species = GameManager.get_species(species_id)
	var base = species.display_name if species else species_id
	return "%s #%d" % [base, catch_number]

func get_iv_summary() -> String:
	return "ATK:%d/SPA:%d/DEF:%d/SPD:%d/RNG:%d" % [iv_phys_attack, iv_spec_attack, iv_defense, iv_speed, iv_range]

# Get all IVs as an array (matches IV_STATS order)
func get_ivs() -> Array[int]:
	var arr: Array[int] = [iv_phys_attack, iv_spec_attack, iv_defense, iv_speed, iv_range]
	return arr

# Check if a specific IV is perfect (31)
func is_iv_perfect(index: int) -> bool:
	return get_ivs()[index] == 31

# Count how many perfect IVs
func perfect_iv_count() -> int:
	var count := 0
	for iv in get_ivs():
		if iv == 31:
			count += 1
	return count

# Check if ALL IVs are perfect
func is_all_perfect() -> bool:
	return perfect_iv_count() == IV_STATS.size()

# IV quality rating: 0-5 stars based on total IV percentage
func get_iv_star_rating() -> int:
	var total := 0
	for iv in get_ivs():
		total += iv
	var max_total := 31 * IV_STATS.size()  # 155
	var ratio := float(total) / float(max_total)
	if ratio >= 0.95:
		return 5
	elif ratio >= 0.80:
		return 4
	elif ratio >= 0.60:
		return 3
	elif ratio >= 0.40:
		return 2
	elif ratio >= 0.20:
		return 1
	else:
		return 0

func get_xp_for_next_level() -> int:
	return level * 100

func get_stat_multiplier() -> float:
	# Legacy - kept for compatibility
	return 1.0 + (level - 1) * 0.1

func add_xp(amount: int) -> bool:
	xp += amount
	var leveled = false
	while xp >= get_xp_for_next_level():
		xp -= get_xp_for_next_level()
		level += 1
		leveled = true
		check_new_moves()
	return leveled

func get_xp_progress() -> float:
	return float(xp) / float(get_xp_for_next_level())

# Check if we learned a new move at current level
func check_new_moves() -> void:
	var species = GameManager.get_species(species_id)
	if not species or species.learnset.is_empty():
		return

	if level in species.learnset:
		var move_id = species.learnset[level]
		if move_id not in known_moves and move_id not in pending_moves:
			if known_moves.size() < 4:
				# Auto-learn if we have room
				known_moves.append(move_id)
			else:
				# Add to pending for player to choose
				pending_moves.append(move_id)

func has_pending_moves() -> bool:
	return pending_moves.size() > 0

# Replace a known move with a pending move
func learn_pending_move(pending_index: int, slot_to_replace: int) -> void:
	if pending_index >= pending_moves.size():
		return
	if slot_to_replace >= known_moves.size():
		return

	var new_move = pending_moves[pending_index]
	known_moves[slot_to_replace] = new_move
	pending_moves.remove_at(pending_index)

# Skip learning a pending move
func skip_pending_move(pending_index: int) -> void:
	if pending_index < pending_moves.size():
		pending_moves.remove_at(pending_index)

# Generate random IVs (call when catching)
func generate_random_ivs() -> void:
	iv_phys_attack = randi_range(0, 31)
	iv_spec_attack = randi_range(0, 31)
	iv_defense = randi_range(0, 31)
	iv_speed = randi_range(0, 31)
	iv_range = randi_range(0, 31)

# Pokemon stat formula: ((base + IV) × 2) × level / 100 + 5
func calc_stat(base: int, iv: int) -> int:
	return int(((base + iv) * 2.0) * level / 100.0) + 5

func get_phys_attack() -> int:
	var species = GameManager.get_species(species_id)
	if species:
		return calc_stat(species.base_phys_attack, iv_phys_attack)
	return 5

func get_spec_attack() -> int:
	var species = GameManager.get_species(species_id)
	if species:
		return calc_stat(species.base_spec_attack, iv_spec_attack)
	return 5

func get_speed() -> int:
	var species = GameManager.get_species(species_id)
	if species:
		return calc_stat(species.base_stat_speed, iv_speed)
	return 5

func get_defense() -> int:
	var species = GameManager.get_species(species_id)
	if species:
		return calc_stat(species.base_defense, iv_defense)
	return 5

func get_range_stat() -> int:
	var species = GameManager.get_species(species_id)
	if species:
		return calc_stat(species.base_stat_range, iv_range)
	return 5

# IV scaling factors for tower stats (0 IV = 1.0x, 31 IV = up to 1.3x)
func get_iv_attack_scale() -> float:
	return 1.0 + (iv_phys_attack / 31.0) * 0.3

func get_iv_defense_scale() -> float:
	return 1.0 + (iv_defense / 31.0) * 0.3

func get_iv_speed_scale() -> float:
	return 1.0 + (iv_speed / 31.0) * 0.3

func get_iv_range_scale() -> float:
	return 1.0 + (iv_range / 31.0) * 0.3

# Learn moves up to current level from learnset
func learn_moves_for_level() -> void:
	var species = GameManager.get_species(species_id)
	if not species or species.learnset.is_empty():
		return

	for learn_level in species.learnset.keys():
		if learn_level <= level:
			var move_id = species.learnset[learn_level]
			if move_id not in known_moves:
				if known_moves.size() < 4:
					known_moves.append(move_id)
				# If already have 4 moves, skip (UI will handle replacement)

func to_dict() -> Dictionary:
	return {
		"uuid": uuid,
		"species_id": species_id,
		"catch_number": catch_number,
		"nickname": nickname,
		"level": level,
		"xp": xp,
		"iv_phys_attack": iv_phys_attack,
		"iv_spec_attack": iv_spec_attack,
		"iv_defense": iv_defense,
		"iv_speed": iv_speed,
		"iv_range": iv_range,
		"known_moves": known_moves
	}

static func from_dict(data: Dictionary) -> CaughtPokemon:
	var pokemon = CaughtPokemon.new()
	pokemon.uuid = data.get("uuid", pokemon.uuid)  # Keep generated if not in data
	pokemon.species_id = data.get("species_id", "")
	pokemon.catch_number = data.get("catch_number", 1)
	pokemon.nickname = data.get("nickname", "")
	pokemon.level = data.get("level", 1)
	pokemon.xp = data.get("xp", 0)
	pokemon.iv_phys_attack = data.get("iv_phys_attack", 0)
	pokemon.iv_spec_attack = data.get("iv_spec_attack", 0)
	pokemon.iv_defense = data.get("iv_defense", 0)
	pokemon.iv_speed = data.get("iv_speed", 0)
	pokemon.iv_range = data.get("iv_range", 0)
	var moves = data.get("known_moves", [])
	pokemon.known_moves.assign(moves)
	return pokemon
