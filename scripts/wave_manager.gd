extends Node
class_name WaveManager

@export var path: NodePath
@export var spawn_interval: float = 0.8

var _path: Path2D
var map_data: MapData

# Fallback scenes for backward compatibility
var enemy_scenes: Dictionary = {
	"caterpie": preload("res://scenes/enemies/caterpie.tscn"),
	"weedle": preload("res://scenes/enemies/weedle.tscn"),
	"pidgey": preload("res://scenes/enemies/pidgey.tscn"),
	"metapod": preload("res://scenes/enemies/metapod.tscn"),
	"kakuna": preload("res://scenes/enemies/kakuna.tscn"),
}

var base_enemy_scene: PackedScene = preload("res://scenes/enemies/base_enemy.tscn")

var spawn_queue: Array = []  # Array of {species_id, level}
var spawn_timer: float = 0.0
var current_spawn_interval: float = 0.8

func _ready() -> void:
	if path:
		_path = get_node(path) as Path2D
	GameManager.wave_changed.connect(_on_wave_changed)

func _on_wave_changed(wave_num: int) -> void:
	start_wave(wave_num)

func start_wave(wave_num: int) -> void:
	var total_waves = 10
	if map_data:
		total_waves = map_data.waves_count

	if wave_num < 1 or wave_num > total_waves:
		return

	# If no map_data or no enemy_pool, use legacy hardcoded waves
	if not map_data or map_data.enemy_pool.is_empty():
		_start_legacy_wave(wave_num)
		return

	var wave_data = generate_wave(wave_num, total_waves)
	spawn_queue.clear()

	for entry in wave_data:
		for i in entry.count:
			spawn_queue.append({"species_id": entry.species_id, "level": entry.level})

	spawn_queue.shuffle()
	spawn_timer = 0.0

	# Decrease spawn interval with difficulty
	var difficulty = map_data.difficulty if map_data else 1
	current_spawn_interval = spawn_interval - (difficulty - 1) * 0.08
	current_spawn_interval = max(current_spawn_interval, 0.3)

func generate_wave(wave_num: int, total_waves: int) -> Array:
	var difficulty = map_data.difficulty
	var base_level = map_data.enemy_level_base
	var enemy_pool = map_data.enemy_pool
	var boss_pool = map_data.boss_pool
	var is_boss_wave = (wave_num % 5 == 0)
	var is_final_wave = (wave_num == total_waves)

	# Scale enemy count: base 5 + difficulty + wave progression
	var base_count = 4 + difficulty + int(wave_num * 1.5)

	# Enemy level scales with wave number
	var level = base_level + int((wave_num - 1) * 1.5)

	var wave: Array = []

	if is_final_wave:
		# Epic final wave: lots of enemies, mixed regular + boss
		var regular_count = base_count + 8
		var boss_count = 3 + difficulty

		# Split regular enemies across pool
		var per_species = max(1, regular_count / enemy_pool.size())
		for species_id in enemy_pool:
			wave.append({"species_id": species_id, "count": per_species, "level": level})

		# Add bosses
		if not boss_pool.is_empty():
			var per_boss = max(1, boss_count / boss_pool.size())
			for species_id in boss_pool:
				wave.append({"species_id": species_id, "count": per_boss, "level": level + 5})

	elif is_boss_wave:
		# Boss wave: fewer but stronger enemies
		if not boss_pool.is_empty():
			var boss_species = boss_pool[randi() % boss_pool.size()]
			wave.append({"species_id": boss_species, "count": 2 + difficulty, "level": level + 3})
		# Add a few regulars as escorts
		var escort_species = enemy_pool[randi() % enemy_pool.size()]
		wave.append({"species_id": escort_species, "count": 3, "level": level})

	else:
		# Regular wave: pick 1-3 species from pool
		var num_species = mini(randi_range(1, 3), enemy_pool.size())
		var shuffled = enemy_pool.duplicate()
		shuffled.shuffle()
		var count_per = max(2, base_count / num_species)
		for i in num_species:
			wave.append({"species_id": shuffled[i], "count": count_per, "level": level})

	return wave

# Legacy wave system for maps without enemy_pool
var legacy_wave_definitions: Array = [
	[{"type": "caterpie", "count": 6}],
	[{"type": "weedle", "count": 6}],
	[{"type": "caterpie", "count": 4}, {"type": "weedle", "count": 4}],
	[{"type": "pidgey", "count": 5}],
	[{"type": "caterpie", "count": 5}, {"type": "pidgey", "count": 3}],
	[{"type": "metapod", "count": 4}, {"type": "caterpie", "count": 6}],
	[{"type": "kakuna", "count": 4}, {"type": "weedle", "count": 6}],
	[{"type": "pidgey", "count": 10}],
	[{"type": "metapod", "count": 5}, {"type": "kakuna", "count": 5}],
	[{"type": "caterpie", "count": 8}, {"type": "weedle", "count": 8}, {"type": "pidgey", "count": 6}, {"type": "metapod", "count": 3}, {"type": "kakuna", "count": 3}],
]

func _start_legacy_wave(wave_num: int) -> void:
	if wave_num < 1 or wave_num > legacy_wave_definitions.size():
		return
	var wave_data = legacy_wave_definitions[wave_num - 1]
	spawn_queue.clear()
	for group in wave_data:
		for i in group.count:
			spawn_queue.append({"species_id": group.type, "level": 1, "legacy": true})
	spawn_queue.shuffle()
	spawn_timer = 0.0
	current_spawn_interval = spawn_interval

func _process(delta: float) -> void:
	if spawn_queue.size() > 0:
		spawn_timer += delta
		if spawn_timer >= current_spawn_interval:
			spawn_timer = 0.0
			spawn_enemy(spawn_queue.pop_front())

func spawn_enemy(entry: Dictionary) -> void:
	if not _path:
		return

	var species_id: String = entry.species_id
	var level: int = entry.get("level", 1)
	var is_legacy: bool = entry.get("legacy", false)

	# For legacy mode, try preloaded scenes first
	if is_legacy and enemy_scenes.has(species_id):
		var enemy = enemy_scenes[species_id].instantiate() as BaseEnemy
		if enemy:
			_path.add_child(enemy)
			enemy.progress = 0
			return

	# Dynamic spawning via base_enemy.tscn
	var enemy = base_enemy_scene.instantiate() as BaseEnemy
	if not enemy:
		return

	enemy.species_id = species_id
	enemy.enemy_level = level
	_path.add_child(enemy)
	enemy.progress = 0
