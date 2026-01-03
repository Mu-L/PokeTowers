extends Node2D

enum Mode { PATH, ZONES }

@onready var line: Line2D = $Line2D
@onready var background: TextureRect = $Background
@onready var map_label: Label = $UI/MainLayout/MapArea/MapLabel
@onready var instructions: Label = $UI/MainLayout/Sidebar/VBox/ModeSection/Instructions
@onready var path_btn: Button = $UI/MainLayout/Sidebar/VBox/ModeSection/ModeButtons/PathBtn
@onready var zones_btn: Button = $UI/MainLayout/Sidebar/VBox/ModeSection/ModeButtons/ZonesBtn
@onready var file_dialog: FileDialog = $UI/FileDialog
@onready var scale_slider: HSlider = $UI/MainLayout/Sidebar/VBox/BGSection/ScaleRow/ScaleSlider
@onready var scale_value: Label = $UI/MainLayout/Sidebar/VBox/BGSection/ScaleRow/ScaleValue
@onready var output_label: Label = $UI/MainLayout/Sidebar/VBox/DataSection/ScrollContainer/Output
@onready var selection_info: Label = $UI/MainLayout/Sidebar/VBox/SelectionSection/SelectionInfo

var waypoints: Array[Vector2] = []
var zones: Array[Vector2] = []
var zone_sizes: Array[float] = []

var current_mode: Mode = Mode.PATH
var selected_point: int = -1
var selected_zone: int = -1
var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

var loaded_bg_path: String = ""
var bg_scale: float = 1.0
var bg_offset: Vector2 = Vector2.ZERO
var dragging_bg: bool = false
var bg_drag_start: Vector2 = Vector2.ZERO

const POINT_RADIUS := 15.0
const DEFAULT_ZONE_SIZE := 40.0
const MIN_ZONE_SIZE := 30.0
const MAX_ZONE_SIZE := 120.0
const ZONE_SIZE_STEP := 10.0
const MAP_WIDTH := 880.0
const MAP_HEIGHT := 720.0

func _ready() -> void:
	line.clear_points()
	load_map_data()
	update_mode_buttons()
	update_instructions()
	update_selection_info()

func load_map_data() -> void:
	var map_data = GameManager.editing_map_data
	if not map_data:
		map_label.text = "No Map Loaded"
		return

	map_label.text = map_data.map_name if map_data.map_name else "Unnamed Map"

	if map_data.background:
		background.texture = map_data.background

	bg_scale = map_data.bg_scale
	bg_offset = map_data.bg_offset
	scale_slider.value = bg_scale
	apply_bg_scale(bg_scale)

	waypoints.clear()
	for pt in map_data.path_points:
		waypoints.append(Vector2(pt.x, pt.y))
	rebuild_line()

	zones.clear()
	zone_sizes.clear()
	for z in map_data.zones:
		zones.append(Vector2(z.x, z.y))
		zone_sizes.append(map_data.zone_size)

	update_output()
	queue_redraw()

func _input(event: InputEvent) -> void:
	# Handle background dragging (middle mouse)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		if event.pressed:
			dragging_bg = true
			bg_drag_start = event.position - bg_offset
		else:
			dragging_bg = false
		return

	if event is InputEventMouseMotion and dragging_bg:
		bg_offset = event.position - bg_drag_start
		apply_bg_scale(bg_scale)
		return

	# Don't process clicks on sidebar
	if event is InputEventMouseButton and event.pressed:
		if event.position.x > MAP_WIDTH:
			return

	if current_mode == Mode.PATH:
		handle_path_input(event)
	else:
		handle_zone_input(event)

func handle_path_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var pos = clamp_to_map(event.position)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var pt = get_point_at(event.position)
				if pt >= 0:
					selected_point = pt
					dragging = true
					drag_offset = waypoints[pt] - event.position
					update_selection_info()
				else:
					if event.shift_pressed and waypoints.size() > 0:
						pos = snap_to_straight(waypoints[-1], pos)
					add_waypoint(pos)
			else:
				dragging = false
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var pt = get_point_at(event.position)
			if pt >= 0:
				delete_point(pt)
			else:
				undo_waypoint()
	elif event is InputEventMouseMotion and dragging and selected_point >= 0:
		var new_pos = clamp_to_map(event.position + drag_offset)
		if Input.is_key_pressed(KEY_SHIFT) and selected_point > 0:
			new_pos = snap_to_straight(waypoints[selected_point - 1], new_pos)
		waypoints[selected_point] = new_pos
		rebuild_line()
		update_output()
		update_selection_info()
		queue_redraw()

func snap_to_straight(from: Vector2, to: Vector2) -> Vector2:
	var dx = abs(to.x - from.x)
	var dy = abs(to.y - from.y)
	if dx < dy:
		return Vector2(from.x, to.y)
	else:
		return Vector2(to.x, from.y)

func handle_zone_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var pos = clamp_to_map(event.position)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var z = get_zone_at(event.position)
				if z >= 0:
					selected_zone = z
					dragging = true
					drag_offset = zones[z] - event.position
					update_selection_info()
				else:
					zones.append(pos)
					zone_sizes.append(DEFAULT_ZONE_SIZE)
					selected_zone = zones.size() - 1
					update_output()
					update_selection_info()
			else:
				dragging = false
			queue_redraw()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var z = get_zone_at(event.position)
			if z >= 0:
				zones.remove_at(z)
				zone_sizes.remove_at(z)
				selected_zone = -1
				update_output()
				update_selection_info()
				queue_redraw()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			if selected_zone >= 0:
				zone_sizes[selected_zone] = min(zone_sizes[selected_zone] + ZONE_SIZE_STEP, MAX_ZONE_SIZE)
				update_output()
				update_selection_info()
				queue_redraw()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			if selected_zone >= 0:
				zone_sizes[selected_zone] = max(zone_sizes[selected_zone] - ZONE_SIZE_STEP, MIN_ZONE_SIZE)
				update_output()
				update_selection_info()
				queue_redraw()
	elif event is InputEventMouseMotion and dragging and selected_zone >= 0:
		zones[selected_zone] = clamp_to_map(event.position + drag_offset)
		update_output()
		update_selection_info()
		queue_redraw()

func clamp_to_map(pos: Vector2) -> Vector2:
	pos.x = clamp(pos.x, 0, MAP_WIDTH)
	pos.y = clamp(pos.y, 0, MAP_HEIGHT)
	return pos

func get_point_at(pos: Vector2) -> int:
	for i in range(waypoints.size()):
		if pos.distance_to(waypoints[i]) < POINT_RADIUS:
			return i
	return -1

func get_segment_at(pos: Vector2) -> int:
	for i in range(waypoints.size() - 1):
		var a = waypoints[i]
		var b = waypoints[i + 1]
		var dist = point_to_segment_dist(pos, a, b)
		if dist < 20:
			return i
	return -1

func point_to_segment_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var ap = p - a
	var t = clamp(ap.dot(ab) / ab.dot(ab), 0.0, 1.0)
	var closest = a + ab * t
	return p.distance_to(closest)

func get_zone_at(pos: Vector2) -> int:
	for i in range(zones.size()):
		var zpos = zones[i]
		var size = zone_sizes[i] if i < zone_sizes.size() else DEFAULT_ZONE_SIZE
		if abs(pos.x - zpos.x) < size / 2 and abs(pos.y - zpos.y) < size / 2:
			return i
	return -1

func add_waypoint(pos: Vector2) -> void:
	waypoints.append(pos)
	line.add_point(pos)
	selected_point = waypoints.size() - 1
	update_output()
	update_selection_info()
	queue_redraw()

func insert_point(idx: int, pos: Vector2) -> void:
	waypoints.insert(idx, pos)
	rebuild_line()
	selected_point = idx
	update_output()
	update_selection_info()
	queue_redraw()

func delete_point(idx: int) -> void:
	if waypoints.size() > 0:
		waypoints.remove_at(idx)
		rebuild_line()
		selected_point = -1
		update_output()
		update_selection_info()
		queue_redraw()

func undo_waypoint() -> void:
	if waypoints.size() > 0:
		waypoints.pop_back()
		line.remove_point(line.get_point_count() - 1)
		selected_point = -1
		update_output()
		update_selection_info()
		queue_redraw()

func rebuild_line() -> void:
	line.clear_points()
	for wp in waypoints:
		line.add_point(wp)

func clear_all() -> void:
	if current_mode == Mode.PATH:
		waypoints.clear()
		line.clear_points()
		selected_point = -1
	else:
		zones.clear()
		zone_sizes.clear()
		selected_zone = -1
	update_output()
	update_selection_info()
	queue_redraw()

func _draw() -> void:
	# Draw game area border (always visible)
	var border_rect = Rect2(0, 0, MAP_WIDTH, MAP_HEIGHT)
	draw_rect(border_rect, Color(1, 0.85, 0.2, 0.8), false, 3.0)
	# Corner markers
	var corner_size = 20.0
	var corner_color = Color(1, 0.85, 0.2, 0.6)
	# Top-left
	draw_line(Vector2(0, 0), Vector2(corner_size, 0), corner_color, 2.0)
	draw_line(Vector2(0, 0), Vector2(0, corner_size), corner_color, 2.0)
	# Top-right
	draw_line(Vector2(MAP_WIDTH, 0), Vector2(MAP_WIDTH - corner_size, 0), corner_color, 2.0)
	draw_line(Vector2(MAP_WIDTH, 0), Vector2(MAP_WIDTH, corner_size), corner_color, 2.0)
	# Bottom-left
	draw_line(Vector2(0, MAP_HEIGHT), Vector2(corner_size, MAP_HEIGHT), corner_color, 2.0)
	draw_line(Vector2(0, MAP_HEIGHT), Vector2(0, MAP_HEIGHT - corner_size), corner_color, 2.0)
	# Bottom-right
	draw_line(Vector2(MAP_WIDTH, MAP_HEIGHT), Vector2(MAP_WIDTH - corner_size, MAP_HEIGHT), corner_color, 2.0)
	draw_line(Vector2(MAP_WIDTH, MAP_HEIGHT), Vector2(MAP_WIDTH, MAP_HEIGHT - corner_size), corner_color, 2.0)
	# Size label
	draw_string(ThemeDB.fallback_font, Vector2(5, 15), "880 x 720", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 0.85, 0.2, 0.7))

	# Draw grid overlay in zones mode
	if current_mode == Mode.ZONES:
		var grid_color = Color(0.3, 0.3, 0.35, 0.3)
		for x in range(0, int(MAP_WIDTH), 40):
			draw_line(Vector2(x, 0), Vector2(x, MAP_HEIGHT), grid_color, 1.0)
		for y in range(0, int(MAP_HEIGHT), 40):
			draw_line(Vector2(0, y), Vector2(MAP_WIDTH, y), grid_color, 1.0)

	# Draw path points
	if current_mode == Mode.PATH:
		for i in range(waypoints.size()):
			var color = Color.GOLD if i == selected_point else Color.WHITE
			var inner_color = Color(0.2, 0.2, 0.2) if i != selected_point else Color(0.3, 0.25, 0.1)
			draw_circle(waypoints[i], POINT_RADIUS, color)
			draw_circle(waypoints[i], POINT_RADIUS - 3, inner_color)
			draw_string(ThemeDB.fallback_font, waypoints[i] + Vector2(-4, 5), str(i), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	else:
		# Dimmed path points when in zones mode
		for i in range(waypoints.size()):
			draw_circle(waypoints[i], POINT_RADIUS * 0.7, Color(0.5, 0.5, 0.5, 0.4))

	# Draw zones
	for i in range(zones.size()):
		var zpos = zones[i]
		var size = zone_sizes[i] if i < zone_sizes.size() else DEFAULT_ZONE_SIZE
		var rect = Rect2(zpos - Vector2(size/2, size/2), Vector2(size, size))

		var fill_color: Color
		var border_color: Color

		if current_mode == Mode.ZONES:
			if i == selected_zone:
				fill_color = Color(1.0, 0.85, 0.2, 0.4)
				border_color = Color.GOLD
			else:
				fill_color = Color(0.3, 0.8, 0.3, 0.4)
				border_color = Color(0.5, 1.0, 0.5)
		else:
			fill_color = Color(0.3, 0.5, 0.3, 0.2)
			border_color = Color(0.4, 0.6, 0.4, 0.5)

		draw_rect(rect, fill_color)
		draw_rect(rect, border_color, false, 2.0)

		# Draw zone number
		var num_color = Color.WHITE if current_mode == Mode.ZONES else Color(0.7, 0.7, 0.7, 0.6)
		draw_string(ThemeDB.fallback_font, zpos + Vector2(-8, 5), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, num_color)

func update_output() -> void:
	var text = "Path: %d points\n" % waypoints.size()
	text += "Zones: %d\n\n" % zones.size()

	if waypoints.size() > 0:
		text += "--- Path ---\n"
		for i in range(waypoints.size()):
			text += "%d: (%d, %d)\n" % [i, int(waypoints[i].x), int(waypoints[i].y)]

	if zones.size() > 0:
		text += "\n--- Zones ---\n"
		for i in range(zones.size()):
			var size = zone_sizes[i] if i < zone_sizes.size() else DEFAULT_ZONE_SIZE
			text += "%d: (%d, %d)\n" % [i + 1, int(zones[i].x), int(zones[i].y)]

	output_label.text = text

func update_selection_info() -> void:
	if current_mode == Mode.PATH and selected_point >= 0:
		var pt = waypoints[selected_point]
		selection_info.text = "Point %d: (%d, %d)" % [selected_point, int(pt.x), int(pt.y)]
	elif current_mode == Mode.ZONES and selected_zone >= 0:
		var z = zones[selected_zone]
		var size = zone_sizes[selected_zone] if selected_zone < zone_sizes.size() else DEFAULT_ZONE_SIZE
		selection_info.text = "Zone %d: (%d, %d) [%d]" % [selected_zone + 1, int(z.x), int(z.y), int(size)]
	else:
		selection_info.text = "None"

func update_mode_buttons() -> void:
	path_btn.button_pressed = current_mode == Mode.PATH
	zones_btn.button_pressed = current_mode == Mode.ZONES

func update_instructions() -> void:
	if current_mode == Mode.PATH:
		instructions.text = "Click: add point\nShift: straight line\nDrag: move point\nRight-click: delete"
	else:
		instructions.text = "Click: add zone\nDrag: move zone\nScroll: resize\nRight-click: delete"

func set_mode(mode: Mode) -> void:
	current_mode = mode
	selected_point = -1
	selected_zone = -1
	dragging = false
	update_mode_buttons()
	update_instructions()
	update_selection_info()
	queue_redraw()

func _on_path_pressed() -> void:
	set_mode(Mode.PATH)

func _on_zones_pressed() -> void:
	set_mode(Mode.ZONES)

func _on_clear_pressed() -> void:
	clear_all()

func _on_copy_pressed() -> void:
	var output = ""

	if waypoints.size() > 0:
		var line_parts: Array[String] = []
		for wp in waypoints:
			line_parts.append("%d, %d" % [int(wp.x), int(wp.y)])
		output += "path_points = PackedVector2Array(%s)\n\n" % ", ".join(line_parts)

	if zones.size() > 0:
		var zone_parts: Array[String] = []
		for z in zones:
			zone_parts.append("%d, %d" % [int(z.x), int(z.y)])
		output += "zones = PackedVector2Array(%s)" % ", ".join(zone_parts)

	if output != "":
		DisplayServer.clipboard_set(output)
		print("Copied to clipboard!")

func _on_save_pressed() -> void:
	var map_data = GameManager.editing_map_data
	if not map_data:
		push_error("No map data to save")
		return

	var path_arr = PackedVector2Array()
	for wp in waypoints:
		path_arr.append(wp)
	map_data.path_points = path_arr

	var zones_arr = PackedVector2Array()
	for z in zones:
		zones_arr.append(z)
	map_data.zones = zones_arr

	map_data.bg_scale = bg_scale
	map_data.bg_offset = bg_offset

	if loaded_bg_path != "" and background.texture:
		var ext = "." + loaded_bg_path.get_extension()
		var dest_name = map_data.get_id() + "_bg" + ext
		var dest_path = "res://assets/maps/" + dest_name

		DirAccess.make_dir_recursive_absolute("res://assets/maps")

		var err = DirAccess.copy_absolute(loaded_bg_path, ProjectSettings.globalize_path(dest_path))
		if err == OK:
			var tex = load(dest_path)
			if tex:
				map_data.background = tex
		loaded_bg_path = ""

	var path = map_data.resource_path
	if path == "":
		path = "res://resources/maps/%s.tres" % map_data.get_id()

	var err = ResourceSaver.save(map_data, path)
	if err == OK:
		print("Saved map to: %s" % path)
	else:
		push_error("Failed to save map: %s" % err)

func _on_load_bg_pressed() -> void:
	file_dialog.popup_centered()

func _on_file_selected(path: String) -> void:
	var img = Image.load_from_file(path)
	if img:
		var tex = ImageTexture.create_from_image(img)
		background.texture = tex
		loaded_bg_path = path
		bg_offset = Vector2.ZERO
		scale_slider.value = 1.0
		apply_bg_scale(1.0)

func _on_scale_changed(value: float) -> void:
	apply_bg_scale(value)

func apply_bg_scale(scale: float) -> void:
	bg_scale = scale
	scale_value.text = "%.2f" % scale

	var map_center = Vector2(MAP_WIDTH / 2, MAP_HEIGHT / 2) + bg_offset
	var new_width = MAP_WIDTH * scale
	var new_height = MAP_HEIGHT * scale

	background.offset_left = map_center.x - new_width / 2
	background.offset_right = map_center.x + new_width / 2
	background.offset_top = map_center.y - new_height / 2
	background.offset_bottom = map_center.y + new_height / 2

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/map_select.tscn")
