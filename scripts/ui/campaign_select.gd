extends Control

@onready var regions_list: VBoxContainer = $MainLayout/LeftPanel/VBox/RegionsScroll/RegionsList
@onready var regions_header: Label = $MainLayout/LeftPanel/VBox/RegionsHeader
@onready var maps_grid: GridContainer = $MainLayout/RightPanel/VBox/MapsScroll/MapsGrid
@onready var region_title: Label = $MainLayout/RightPanel/VBox/RegionTitle
@onready var start_btn: Button = $MainLayout/RightPanel/VBox/ButtonsHBox/StartBtn
@onready var back_btn: Button = $MainLayout/RightPanel/VBox/ButtonsHBox/BackBtn
@onready var left_panel: PanelContainer = $MainLayout/LeftPanel
@onready var right_panel: PanelContainer = $MainLayout/RightPanel

var campaigns: Array[CampaignData] = []
var selected_campaign: CampaignData = null
var selected_map: MapData = null
var selected_map_index: int = -1
var selected_map_card: PanelContainer = null
var region_buttons: Array[Button] = []
var pulse_tween: Tween

enum MapState { LOCKED, AVAILABLE, COMPLETED }

func _ready() -> void:
	style_ui()
	load_campaigns()
	populate_regions()
	start_btn.disabled = true

func style_ui() -> void:
	# Left panel - dark semi-transparent
	var left_style = StyleBoxFlat.new()
	left_style.bg_color = Color(0.1, 0.12, 0.18, 0.95)
	left_style.set_corner_radius_all(10)
	left_style.set_content_margin_all(10)
	left_panel.add_theme_stylebox_override("panel", left_style)

	# Right panel - slightly lighter
	var right_style = StyleBoxFlat.new()
	right_style.bg_color = Color(0.15, 0.18, 0.25, 0.95)
	right_style.set_corner_radius_all(10)
	right_style.set_content_margin_all(15)
	right_panel.add_theme_stylebox_override("panel", right_style)

	# Header styling
	regions_header.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))

	# Back button - neutral
	style_button_neutral(back_btn)

	# Start button - green (will be styled more when enabled)
	style_button_start_disabled()

func style_button_neutral(btn: Button) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.32, 0.38)
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.border_color = Color(0.4, 0.42, 0.5)
	btn.add_theme_stylebox_override("normal", style)

	var hover = style.duplicate()
	hover.bg_color = Color(0.38, 0.4, 0.48)
	btn.add_theme_stylebox_override("hover", hover)

	btn.add_theme_color_override("font_color", Color.WHITE)

func style_button_start_disabled() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.25, 0.35, 0.28)
	style.set_corner_radius_all(10)
	style.set_border_width_all(3)
	style.border_color = Color(0.2, 0.3, 0.22)
	start_btn.add_theme_stylebox_override("normal", style)
	start_btn.add_theme_stylebox_override("disabled", style)
	start_btn.add_theme_color_override("font_color", Color(0.5, 0.6, 0.5))
	start_btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.5, 0.4))

func style_button_start_locked() -> void:
	if pulse_tween:
		pulse_tween.kill()
	start_btn.scale = Vector2.ONE
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.35, 0.2, 0.2)
	style.set_corner_radius_all(10)
	style.set_border_width_all(3)
	style.border_color = Color(0.45, 0.25, 0.25)
	start_btn.add_theme_stylebox_override("normal", style)
	start_btn.add_theme_stylebox_override("disabled", style)
	start_btn.add_theme_color_override("font_color", Color(0.7, 0.5, 0.5))
	start_btn.add_theme_color_override("font_disabled_color", Color(0.6, 0.45, 0.45))

func style_button_start_enabled() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.65, 0.3)
	style.set_corner_radius_all(10)
	style.set_border_width_all(3)
	style.border_color = Color(0.15, 0.5, 0.2)
	start_btn.add_theme_stylebox_override("normal", style)

	var hover = style.duplicate()
	hover.bg_color = Color(0.25, 0.75, 0.35)
	start_btn.add_theme_stylebox_override("hover", hover)

	var pressed = style.duplicate()
	pressed.bg_color = Color(0.15, 0.55, 0.25)
	start_btn.add_theme_stylebox_override("pressed", pressed)

	start_btn.add_theme_color_override("font_color", Color.WHITE)
	start_btn.add_theme_color_override("font_hover_color", Color.WHITE)

	# Start pulsing animation
	if pulse_tween:
		pulse_tween.kill()
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(start_btn, "scale", Vector2(1.05, 1.05), 0.5).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(start_btn, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_IN_OUT)

func load_campaigns() -> void:
	var dir = DirAccess.open("res://resources/campaigns")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var campaign = load("res://resources/campaigns/" + file_name) as CampaignData
				if campaign:
					campaigns.append(campaign)
			file_name = dir.get_next()
	campaigns.sort_custom(func(a, b): return a.generation < b.generation)

func populate_regions() -> void:
	for child in regions_list.get_children():
		child.queue_free()
	region_buttons.clear()

	for campaign in campaigns:
		var btn = Button.new()
		var locked = not GameManager.is_generation_unlocked(campaign.generation)
		if locked:
			btn.text = "🔒 Gen %d: %s" % [campaign.generation, campaign.region_name]
		else:
			btn.text = "Gen %d: %s" % [campaign.generation, campaign.region_name]
		btn.custom_minimum_size = Vector2(160, 40)
		btn.pressed.connect(_on_region_selected.bind(campaign, btn))
		style_region_button(btn, false, locked)
		regions_list.add_child(btn)
		region_buttons.append(btn)

	if campaigns.size() > 0:
		_on_region_selected(campaigns[0], region_buttons[0])

func style_region_button(btn: Button, selected: bool, locked: bool = false) -> void:
	var style = StyleBoxFlat.new()
	if locked:
		style.bg_color = Color(0.15, 0.15, 0.18)
		style.border_color = Color(0.25, 0.25, 0.3)
	elif selected:
		style.bg_color = Color(0.3, 0.5, 0.7)
		style.border_color = Color(0.4, 0.6, 0.85)
	else:
		style.bg_color = Color(0.2, 0.22, 0.28)
		style.border_color = Color(0.3, 0.32, 0.4)
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	btn.add_theme_stylebox_override("normal", style)

	var hover = style.duplicate()
	hover.bg_color = style.bg_color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover)

	if locked:
		btn.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
	else:
		btn.add_theme_color_override("font_color", Color.WHITE if selected else Color(0.8, 0.82, 0.88))

func _on_region_selected(campaign: CampaignData, btn: Button) -> void:
	selected_campaign = campaign
	selected_map = null
	selected_map_index = -1
	selected_map_card = null
	start_btn.disabled = true
	start_btn.text = "SELECT A MAP"
	style_button_start_disabled()
	if pulse_tween:
		pulse_tween.kill()
	start_btn.scale = Vector2.ONE

	# Update region button highlights
	for i in range(region_buttons.size()):
		var c = campaigns[i]
		var locked = not GameManager.is_generation_unlocked(c.generation)
		style_region_button(region_buttons[i], region_buttons[i] == btn, locked)

	# Show progress
	var progress = GameManager.get_campaign_progress(campaign)
	var total = campaign.maps.size()
	region_title.text = "%s Region (%d/%d)" % [campaign.region_name, progress, total]
	populate_maps(campaign)

func populate_maps(campaign: CampaignData) -> void:
	for child in maps_grid.get_children():
		child.queue_free()

	for i in range(campaign.maps.size()):
		var map_data = campaign.maps[i]
		var state = get_map_state(i)
		var card = create_map_card(map_data, i, state)
		maps_grid.add_child(card)

func get_map_state(index: int) -> MapState:
	if not selected_campaign:
		return MapState.LOCKED
	var map_data = selected_campaign.maps[index]
	if GameManager.is_map_completed(map_data.get_id()):
		return MapState.COMPLETED
	elif GameManager.is_map_unlocked(selected_campaign, index):
		return MapState.AVAILABLE
	return MapState.LOCKED

func create_map_card(map_data: MapData, index: int, state: MapState) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 140)
	style_map_card(panel, false, state)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Container for thumbnail + lock overlay
	var thumb_container = Control.new()
	thumb_container.custom_minimum_size = Vector2(160, 60)
	thumb_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(thumb_container)

	# Map thumbnail placeholder (colored box based on difficulty)
	var thumb = ColorRect.new()
	thumb.set_anchors_preset(Control.PRESET_FULL_RECT)
	var base_color = get_difficulty_color(map_data.difficulty)
	if state == MapState.LOCKED:
		thumb.color = Color(base_color.r * 0.3, base_color.g * 0.3, base_color.b * 0.3)
	else:
		thumb.color = base_color
	thumb_container.add_child(thumb)

	# Lock icon overlay for locked maps
	if state == MapState.LOCKED:
		var lock_label = Label.new()
		lock_label.text = "🔒"
		lock_label.add_theme_font_size_override("font_size", 28)
		lock_label.set_anchors_preset(Control.PRESET_CENTER)
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_label.modulate.a = 0.8
		thumb_container.add_child(lock_label)

	# Checkmark for completed maps
	if state == MapState.COMPLETED:
		var check_label = Label.new()
		check_label.text = "✓"
		check_label.add_theme_font_size_override("font_size", 24)
		check_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
		check_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		check_label.position = Vector2(-28, 2)
		thumb_container.add_child(check_label)

	# Map number + name
	var name_label = Label.new()
	name_label.text = "%d. %s" % [index + 1, map_data.map_name]
	name_label.add_theme_font_size_override("font_size", 13)
	if state == MapState.LOCKED:
		name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	else:
		name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Stars + waves
	var info_hbox = HBoxContainer.new()
	info_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(info_hbox)

	var stars_label = Label.new()
	var stars = "★".repeat(map_data.difficulty) + "☆".repeat(5 - map_data.difficulty)
	stars_label.text = stars
	stars_label.add_theme_font_size_override("font_size", 12)
	if state == MapState.LOCKED:
		stars_label.add_theme_color_override("font_color", Color(0.4, 0.35, 0.2))
	else:
		stars_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	info_hbox.add_child(stars_label)

	var waves_label = Label.new()
	waves_label.text = "  %d waves" % map_data.waves_count
	waves_label.add_theme_font_size_override("font_size", 11)
	if state == MapState.LOCKED:
		waves_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	else:
		waves_label.add_theme_color_override("font_color", Color(0.7, 0.72, 0.8))
	info_hbox.add_child(waves_label)

	# Make entire card clickable
	panel.gui_input.connect(_on_card_input.bind(map_data, panel, index))
	panel.mouse_entered.connect(_on_card_hover.bind(panel, true))
	panel.mouse_exited.connect(_on_card_hover.bind(panel, false))

	panel.set_meta("map_data", map_data)
	panel.set_meta("map_index", index)
	panel.set_meta("map_state", state)
	return panel

func get_difficulty_color(difficulty: int) -> Color:
	match difficulty:
		1: return Color(0.3, 0.6, 0.35)  # Easy - green
		2: return Color(0.4, 0.55, 0.3)  # Normal - yellow-green
		3: return Color(0.6, 0.5, 0.25)  # Medium - orange
		4: return Color(0.65, 0.35, 0.25)  # Hard - red-orange
		5: return Color(0.6, 0.25, 0.3)  # Very Hard - red
		_: return Color(0.4, 0.42, 0.48)

func style_map_card(panel: PanelContainer, selected: bool, state: MapState = MapState.AVAILABLE) -> void:
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(10)
	style.set_content_margin_all(10)
	style.set_border_width_all(3)

	if state == MapState.LOCKED:
		style.bg_color = Color(0.12, 0.13, 0.18)
		style.border_color = Color(0.2, 0.2, 0.25)
	elif state == MapState.COMPLETED:
		style.bg_color = Color(0.18, 0.22, 0.2)
		if selected:
			style.border_color = Color(1, 0.85, 0.2)
		else:
			style.border_color = Color(0.25, 0.45, 0.35)
	else:
		style.bg_color = Color(0.18, 0.2, 0.28)
		if selected:
			style.border_color = Color(1, 0.85, 0.2)
		else:
			style.border_color = Color(0.3, 0.32, 0.4)

	panel.add_theme_stylebox_override("panel", style)

func _on_card_input(event: InputEvent, map_data: MapData, panel: PanelContainer, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_map(map_data, panel, index)
		# Double click to start (only if unlocked)
		var state = panel.get_meta("map_state") as MapState
		if event.double_click and selected_map and state != MapState.LOCKED:
			_on_start_pressed()

func _on_card_hover(panel: PanelContainer, hovering: bool) -> void:
	if panel != selected_map_card:
		var state = panel.get_meta("map_state") as MapState
		if state == MapState.LOCKED:
			return  # No hover effect for locked
		var style = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if hovering:
			style.border_color = Color(0.5, 0.55, 0.65)
		else:
			style.border_color = Color(0.3, 0.32, 0.4) if state == MapState.AVAILABLE else Color(0.25, 0.45, 0.35)
		panel.add_theme_stylebox_override("panel", style)

func select_map(map_data: MapData, panel: PanelContainer, index: int) -> void:
	var state = panel.get_meta("map_state") as MapState

	# Deselect previous
	if selected_map_card and selected_map_card != panel:
		var prev_state = selected_map_card.get_meta("map_state") as MapState
		style_map_card(selected_map_card, false, prev_state)

	selected_map = map_data
	selected_map_index = index
	selected_map_card = panel
	style_map_card(panel, true, state)

	if state == MapState.LOCKED:
		start_btn.disabled = true
		# Show what needs to be completed
		if index > 0:
			var prev_map = selected_campaign.maps[index - 1]
			start_btn.text = "🔒 Complete %s" % prev_map.map_name
		else:
			start_btn.text = "🔒 LOCKED"
		style_button_start_locked()
	else:
		start_btn.disabled = false
		if state == MapState.COMPLETED:
			start_btn.text = "REPLAY: %s" % map_data.map_name
		else:
			start_btn.text = "START: %s" % map_data.map_name
		style_button_start_enabled()

func _on_start_pressed() -> void:
	if selected_map:
		GameManager.selected_map = selected_map
		GameManager.waves_total = selected_map.waves_count
		get_tree().change_scene_to_file("res://scenes/ui/party_select.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
