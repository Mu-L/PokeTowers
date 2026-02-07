extends Node2D

@export var map_data: MapData

@onready var wave_manager: WaveManager = $WaveManager
@onready var background: TextureRect = $Background
@onready var enemy_path: Path2D = $EnemyPath
@onready var path_line: Line2D = $EnemyPath/PathLine
@onready var tower_placement: TowerPlacement = $TowerPlacement

func _ready() -> void:
	# Use selected map from GameManager if available, else fall back to export
	var active_map = GameManager.selected_map if GameManager.selected_map else map_data
	if active_map:
		load_map(active_map)
		wave_manager.map_data = active_map

const MAP_WIDTH := 880.0
const MAP_HEIGHT := 720.0

func load_map(data: MapData) -> void:
	background.texture = data.background
	apply_bg_transform(data.bg_scale, data.bg_offset)

	# Set path curve
	var curve = Curve2D.new()
	for point in data.path_points:
		curve.add_point(point)
	enemy_path.curve = curve

	# Set path line visual
	path_line.clear_points()
	for point in data.path_points:
		path_line.add_point(point)

	# Load zones
	tower_placement.load_zones_from_map(data)

func apply_bg_transform(scale: float, offset: Vector2) -> void:
	var map_center = Vector2(MAP_WIDTH / 2, MAP_HEIGHT / 2) + offset
	var new_width = MAP_WIDTH * scale
	var new_height = MAP_HEIGHT * scale
	background.offset_left = map_center.x - new_width / 2
	background.offset_right = map_center.x + new_width / 2
	background.offset_top = map_center.y - new_height / 2
	background.offset_bottom = map_center.y + new_height / 2
