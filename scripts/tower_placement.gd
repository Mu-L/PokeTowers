extends Node2D
class_name TowerPlacement

@export var invalid_color: Color = Color(1, 0.3, 0.3, 0.5)
@export var valid_color: Color = Color(0.3, 1, 0.3, 0.5)
@export var hover_color: Color = Color(1, 1, 1, 0.6)


var ghost_tower: Node2D = null
var ghost_sprite: Sprite2D = null
var can_place: bool = false
var current_zone: Area2D = null
var occupied_zones: Dictionary = {}  # zone -> tower

@onready var towers_container: Node2D = $TowersContainer
@onready var placement_zones: Node2D = $PlacementZones

var zone_size: int = 40

func _ready() -> void:
	pass

func load_zones_from_map(map_data: MapData) -> void:
	# Clear existing zones
	for child in placement_zones.get_children():
		child.queue_free()
	occupied_zones.clear()

	zone_size = map_data.zone_size
	var half_size = zone_size / 2

	# Spawn zones from map data
	for i in range(map_data.zones.size()):
		var pos = map_data.zones[i]
		var zone = Area2D.new()
		zone.name = "Zone%d" % (i + 1)
		zone.position = pos
		zone.collision_layer = 8
		zone.collision_mask = 0

		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(zone_size, zone_size)
		shape.shape = rect
		zone.add_child(shape)

		var visual = ColorRect.new()
		visual.name = "Visual"
		visual.offset_left = -half_size
		visual.offset_top = -half_size
		visual.offset_right = half_size
		visual.offset_bottom = half_size
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual.color = Color(0.3, 0.5, 0.3, 0.4)
		visual.visible = false  # Hidden by default
		zone.add_child(visual)

		placement_zones.add_child(zone)

func _process(_delta: float) -> void:
	if GameManager.is_placing_tower:
		update_ghost_tower()
	elif ghost_tower:
		remove_ghost_tower()

	update_zone_visuals()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if GameManager.is_placing_tower and can_place and current_zone:
				place_tower()
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			GameManager.cancel_placement()

func get_zone_at_mouse() -> Area2D:
	var mouse_pos = get_global_mouse_position()
	var half_size = zone_size / 2
	for zone in placement_zones.get_children():
		if zone is Area2D:
			var dist = mouse_pos.distance_to(zone.global_position)
			if dist < half_size:
				return zone
	return null

func update_ghost_tower() -> void:
	if not ghost_tower:
		create_ghost_tower()

	current_zone = get_zone_at_mouse()

	if ghost_tower and current_zone:
		# Snap to zone center
		ghost_tower.global_position = current_zone.global_position
		can_place = not is_zone_occupied(current_zone)
		update_ghost_color()
	elif ghost_tower:
		# Follow mouse when not over a zone
		ghost_tower.global_position = get_global_mouse_position()
		can_place = false
		update_ghost_color()

func create_ghost_tower() -> void:
	var caught = GameManager.selected_caught_pokemon
	if not caught:
		return

	var species = GameManager.get_species(caught.species_id)
	if not species or not species.tower_scene:
		return

	ghost_tower = species.tower_scene.instantiate()
	ghost_tower.set_process(false)

	# Assign caught pokemon BEFORE adding to tree so sprite gets set
	if "caught_pokemon" in ghost_tower:
		ghost_tower.caught_pokemon = caught

	add_child(ghost_tower)

	ghost_sprite = ghost_tower.get_node_or_null("Sprite2D")
	if ghost_tower.has_method("show_range_indicator"):
		ghost_tower.show_range_indicator()

func remove_ghost_tower() -> void:
	if ghost_tower:
		ghost_tower.queue_free()
		ghost_tower = null
		ghost_sprite = null

func update_ghost_color() -> void:
	if ghost_sprite:
		ghost_sprite.modulate = valid_color if can_place else invalid_color

func is_zone_occupied(zone: Area2D) -> bool:
	return zone in occupied_zones

func update_zone_visuals() -> void:
	for zone in placement_zones.get_children():
		if zone is Area2D:
			var visual = zone.get_node_or_null("Visual")
			if visual:
				# Only show zones during placement, hide occupied zones
				visual.visible = GameManager.is_placing_tower and not is_zone_occupied(zone)

				if visual.visible:
					if zone == current_zone:
						visual.color = valid_color
					else:
						visual.color = Color(0.3, 0.5, 0.3, 0.4)  # Default

func place_tower() -> void:
	if not current_zone:
		return

	var caught = GameManager.selected_caught_pokemon
	if not caught:
		return

	var species = GameManager.get_species(caught.species_id)
	if not species or not species.tower_scene:
		return

	if not GameManager.spend_currency(species.deploy_cost):
		return

	var tower = species.tower_scene.instantiate()
	tower.global_position = current_zone.global_position

	# Assign caught pokemon BEFORE adding to tree so _ready() can use it
	if "caught_pokemon" in tower:
		tower.caught_pokemon = caught

	towers_container.add_child(tower)

	# Mark zone as occupied
	occupied_zones[current_zone] = tower

	GameManager.cancel_placement()
