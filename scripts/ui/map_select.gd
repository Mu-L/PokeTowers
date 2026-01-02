extends Control

@onready var map_grid: GridContainer = $CenterContainer/VBox/ScrollContainer/MapGrid

var maps: Array[MapData] = []

func _ready() -> void:
	load_maps()
	populate_grid()

func load_maps() -> void:
	maps.clear()
	var dir = DirAccess.open("res://resources/maps")
	if not dir:
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path = "res://resources/maps/" + file_name
			var map_data = load(path) as MapData
			if map_data:
				maps.append(map_data)
		file_name = dir.get_next()
	dir.list_dir_end()

	# Sort by name
	maps.sort_custom(func(a, b): return a.map_name < b.map_name)

func populate_grid() -> void:
	for child in map_grid.get_children():
		child.queue_free()

	for map_data in maps:
		var card = create_map_card(map_data)
		map_grid.add_child(card)

func create_map_card(map_data: MapData) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(160, 140)
	card.set_meta("map_data", map_data)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	# Thumbnail
	var thumb = TextureRect.new()
	thumb.custom_minimum_size = Vector2(144, 80)
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	thumb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if map_data.background:
		thumb.texture = map_data.background
	else:
		# Placeholder grey
		var placeholder = PlaceholderTexture2D.new()
		placeholder.size = Vector2(144, 80)
		thumb.texture = placeholder
	vbox.add_child(thumb)

	# Name
	var name_label = Label.new()
	name_label.text = map_data.map_name if map_data.map_name else "Unnamed"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.clip_text = true
	vbox.add_child(name_label)

	# Difficulty stars
	var diff_label = Label.new()
	var stars = ""
	for i in map_data.difficulty:
		stars += "★"
	for i in range(map_data.difficulty, 5):
		stars += "☆"
	diff_label.text = stars
	diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_label.add_theme_font_size_override("font_size", 10)
	diff_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	vbox.add_child(diff_label)

	# Style
	style_card(card)

	# Click handler
	card.gui_input.connect(_on_card_input.bind(map_data))
	card.mouse_entered.connect(_on_card_hover.bind(card, true))
	card.mouse_exited.connect(_on_card_hover.bind(card, false))

	return card

func style_card(card: PanelContainer, hover: bool = false) -> void:
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	style.bg_color = Color(0.15, 0.15, 0.2) if not hover else Color(0.18, 0.18, 0.25)
	style.border_color = Color(0.3, 0.3, 0.4) if not hover else Color(0.4, 0.5, 0.6)
	style.set_border_width_all(2)
	card.add_theme_stylebox_override("panel", style)

func _on_card_input(event: InputEvent, map_data: MapData) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		open_editor(map_data)

func _on_card_hover(card: PanelContainer, hovering: bool) -> void:
	style_card(card, hovering)

func open_editor(map_data: MapData) -> void:
	GameManager.editing_map_data = map_data
	get_tree().change_scene_to_file("res://scenes/tools/path_editor.tscn")

func _on_new_map_pressed() -> void:
	# Create new map with default values
	var new_map = MapData.new()
	new_map.map_name = "New Map"
	new_map.difficulty = 1
	new_map.zone_size = 40
	new_map.waves_count = 10

	# Generate unique filename
	var base_name = "new_map"
	var counter = 1
	var file_path = "res://resources/maps/%s.tres" % base_name
	while FileAccess.file_exists(file_path):
		file_path = "res://resources/maps/%s_%d.tres" % [base_name, counter]
		counter += 1

	# Save the new map
	var err = ResourceSaver.save(new_map, file_path)
	if err == OK:
		new_map.take_over_path(file_path)
		GameManager.editing_map_data = new_map
		get_tree().change_scene_to_file("res://scenes/tools/path_editor.tscn")
	else:
		push_error("Failed to create new map: %s" % err)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
