extends Control

const STARTERS = [
	{
		"id": "bulbasaur",
		"name": "Bulbasaur",
		"type": "Grass",
		"type_color": Color(0.4, 0.8, 0.4),
		"glow_color": Color(0.4, 0.8, 0.4, 0.3),
		"role": "DoT / Poison",
		"desc": "Poison Seeds"
	},
	{
		"id": "charmander",
		"name": "Charmander",
		"type": "Fire",
		"type_color": Color(1, 0.4, 0.2),
		"glow_color": Color(1, 0.4, 0.2, 0.3),
		"role": "AoE / Splash",
		"desc": "Fireballs"
	},
	{
		"id": "squirtle",
		"name": "Squirtle",
		"type": "Water",
		"type_color": Color(0.3, 0.6, 1),
		"glow_color": Color(0.3, 0.6, 1, 0.3),
		"role": "CC / Slow",
		"desc": "Slowing Shots"
	}
]

@onready var cards_container: HBoxContainer = $Content/CardsSection
@onready var start_btn: Button = $Content/BottomSection/StartBtn
@onready var back_btn: Button = $Content/BottomSection/BackBtn

var selected_id: String = ""
var card_panels: Array[PanelContainer] = []
var pulse_tween: Tween

func _ready() -> void:
	create_cards()
	style_buttons()
	start_btn.disabled = true

func create_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()
	card_panels.clear()

	for starter in STARTERS:
		var card = create_starter_card(starter)
		cards_container.add_child(card)
		card_panels.append(card)

func create_starter_card(data: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 340)
	panel.set_meta("starter_id", data.id)
	style_card(panel, false)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	# Type glow behind sprite
	var glow_container = CenterContainer.new()
	vbox.add_child(glow_container)

	var glow = ColorRect.new()
	glow.custom_minimum_size = Vector2(140, 140)
	glow.color = data.glow_color
	glow.set_anchors_preset(Control.PRESET_CENTER)
	glow_container.add_child(glow)

	# Pedestal
	var pedestal = ColorRect.new()
	pedestal.custom_minimum_size = Vector2(120, 20)
	pedestal.color = Color(0.2, 0.22, 0.28)
	pedestal.set_anchors_preset(Control.PRESET_CENTER)
	pedestal.position.y = 60
	glow_container.add_child(pedestal)

	# Large sprite
	var sprite_container = CenterContainer.new()
	sprite_container.custom_minimum_size = Vector2(140, 140)
	glow_container.add_child(sprite_container)

	var sprite = TextureRect.new()
	sprite.custom_minimum_size = Vector2(120, 120)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sprite_path = "res://assets/sprites/%s.png" % data.id
	if ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
	sprite_container.add_child(sprite)
	panel.set_meta("sprite", sprite)

	# Name
	var name_label = Label.new()
	name_label.text = data.name
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Type badge
	var type_container = CenterContainer.new()
	vbox.add_child(type_container)

	var type_bg = PanelContainer.new()
	var type_style = StyleBoxFlat.new()
	type_style.bg_color = data.type_color.darkened(0.3)
	type_style.set_corner_radius_all(12)
	type_style.set_content_margin_all(6)
	type_style.content_margin_left = 12
	type_style.content_margin_right = 12
	type_bg.add_theme_stylebox_override("panel", type_style)
	type_container.add_child(type_bg)

	var type_label = Label.new()
	type_label.text = data.type
	type_label.add_theme_font_size_override("font_size", 12)
	type_label.add_theme_color_override("font_color", Color.WHITE)
	type_bg.add_child(type_label)

	# Role tag
	var role_label = Label.new()
	role_label.text = data.role
	role_label.add_theme_font_size_override("font_size", 11)
	role_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(role_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = data.desc
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_label)

	# Click handling
	panel.gui_input.connect(_on_card_input.bind(data.id, panel))
	panel.mouse_entered.connect(_on_card_hover.bind(panel, true))
	panel.mouse_exited.connect(_on_card_hover.bind(panel, false))

	return panel

func style_card(panel: PanelContainer, selected: bool) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.17, 0.22) if not selected else Color(0.18, 0.22, 0.28)
	style.set_corner_radius_all(16)
	style.set_border_width_all(4)
	style.border_color = Color(1, 0.85, 0.2) if selected else Color(0.25, 0.28, 0.35)
	panel.add_theme_stylebox_override("panel", style)

func style_buttons() -> void:
	# Start button - green when enabled
	var start_style = StyleBoxFlat.new()
	start_style.bg_color = Color(0.2, 0.5, 0.25)
	start_style.set_corner_radius_all(12)
	start_style.set_border_width_all(3)
	start_style.border_color = Color(0.15, 0.4, 0.2)
	start_btn.add_theme_stylebox_override("disabled", start_style)

	var start_normal = start_style.duplicate()
	start_normal.bg_color = Color(0.2, 0.65, 0.3)
	start_normal.border_color = Color(0.15, 0.5, 0.2)
	start_btn.add_theme_stylebox_override("normal", start_normal)

	var start_hover = start_style.duplicate()
	start_hover.bg_color = Color(0.25, 0.75, 0.35)
	start_btn.add_theme_stylebox_override("hover", start_hover)

	start_btn.add_theme_color_override("font_color", Color.WHITE)
	start_btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.6, 0.5))

	# Back button - neutral
	var back_style = StyleBoxFlat.new()
	back_style.bg_color = Color(0.25, 0.27, 0.32)
	back_style.set_corner_radius_all(8)
	back_style.set_border_width_all(2)
	back_style.border_color = Color(0.35, 0.38, 0.45)
	back_btn.add_theme_stylebox_override("normal", back_style)

	var back_hover = back_style.duplicate()
	back_hover.bg_color = Color(0.32, 0.35, 0.42)
	back_btn.add_theme_stylebox_override("hover", back_hover)

	back_btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))

func _on_card_input(event: InputEvent, starter_id: String, panel: PanelContainer) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_card(starter_id)
		# Double click to start
		if event.double_click and selected_id != "":
			confirm_selection()

func _on_card_hover(panel: PanelContainer, hovering: bool) -> void:
	var starter_id = panel.get_meta("starter_id")
	if starter_id == selected_id:
		return  # Don't change selected card

	var style = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.border_color = Color(0.45, 0.48, 0.55) if hovering else Color(0.25, 0.28, 0.35)
	panel.add_theme_stylebox_override("panel", style)

func select_card(starter_id: String) -> void:
	selected_id = starter_id

	# Update all cards
	for panel in card_panels:
		var id = panel.get_meta("starter_id")
		var is_selected = id == selected_id
		style_card(panel, is_selected)

		# Dim/brighten and scale
		var sprite = panel.get_meta("sprite") as TextureRect
		if is_selected:
			panel.modulate = Color.WHITE
			if sprite:
				var tween = create_tween()
				tween.tween_property(panel, "scale", Vector2(1.05, 1.05), 0.15).set_ease(Tween.EASE_OUT)
		else:
			panel.modulate = Color(0.7, 0.7, 0.7)
			var tween = create_tween()
			tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT)

	# Enable start button
	start_btn.disabled = false
	start_btn.text = "START JOURNEY WITH %s" % starter_id.to_upper()

	# Pulse animation
	if pulse_tween:
		pulse_tween.kill()
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(start_btn, "scale", Vector2(1.03, 1.03), 0.4).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(start_btn, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_IN_OUT)

func confirm_selection() -> void:
	if selected_id == "":
		return

	var caught = CaughtPokemon.new()
	caught.species_id = selected_id
	caught.level = 5
	GameManager.pokedex[selected_id] = caught
	GameManager.starter_pokemon = selected_id
	# Add to party so it's available as tower
	if selected_id not in GameManager.party:
		GameManager.party.append(selected_id)
	SaveManager.save_game()
	get_tree().change_scene_to_file("res://scenes/ui/campaign_select.tscn")

func _on_start_pressed() -> void:
	confirm_selection()

func _on_back_pressed() -> void:
	SaveManager.current_slot = -1
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
