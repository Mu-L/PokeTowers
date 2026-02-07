class_name MapData extends Resource

@export var map_id: String = ""  # Unique ID for progression tracking
@export var map_name: String = ""
@export var description: String = ""
@export var difficulty: int = 1  # 1-5 stars
@export var background: Texture2D
@export var bg_scale: float = 1.0
@export var bg_offset: Vector2 = Vector2.ZERO
@export var path_points: PackedVector2Array = PackedVector2Array()
@export var zones: PackedVector2Array = PackedVector2Array()
@export var zone_size: int = 40
@export var waves_count: int = 10
@export var enemy_pool: Array[String] = []
@export var boss_pool: Array[String] = []
@export var enemy_level_base: int = 1

func get_id() -> String:
	if map_id != "":
		return map_id
	# Auto-generate from map_name: "Route 1" -> "route_1"
	return map_name.to_lower().replace(" ", "_").replace("'", "")
