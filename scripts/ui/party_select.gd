extends Control

const MAX_PARTY = 6

@onready var pokemon_grid: GridContainer = $CenterContainer/VBox/ScrollContainer/PokemonGrid
@onready var selected_label: Label = $CenterContainer/VBox/SelectedLabel
@onready var confirm_btn: Button = $CenterContainer/VBox/HBox/ConfirmBtn

var selected: Array[String] = []

func _ready() -> void:
	populate_pokemon()
	update_ui()

func populate_pokemon() -> void:
	for child in pokemon_grid.get_children():
		child.queue_free()

	for species_id in GameManager.pokedex.keys():
		var caught = GameManager.pokedex[species_id] as CaughtPokemon
		var species = GameManager.get_species(species_id)
		if not species:
			continue

		var card = create_pokemon_card(species_id, species, caught)
		pokemon_grid.add_child(card)

func create_pokemon_card(species_id: String, species: PokemonSpecies, caught: CaughtPokemon) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(100, 140)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# Icon
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if species.icon:
		icon.texture = species.icon
	vbox.add_child(icon)

	# Name
	var name_label = Label.new()
	name_label.text = species.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(name_label)

	# Level
	var level_label = Label.new()
	level_label.text = "Lv. %d" % caught.level
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 10)
	level_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(level_label)

	# Select button
	var btn = Button.new()
	btn.text = "Select"
	btn.add_theme_font_size_override("font_size", 11)
	style_button(btn, false)
	btn.pressed.connect(_on_pokemon_toggled.bind(species_id, btn, panel))
	vbox.add_child(btn)

	panel.set_meta("species_id", species_id)
	panel.set_meta("btn", btn)
	style_card(panel, false)

	return panel

func _on_pokemon_toggled(species_id: String, btn: Button, panel: PanelContainer) -> void:
	if species_id in selected:
		selected.erase(species_id)
		btn.text = "Select"
		style_button(btn, false)
		style_card(panel, false)
	elif selected.size() < MAX_PARTY:
		selected.append(species_id)
		btn.text = "✓ In Party"
		style_button(btn, true)
		style_card(panel, true)
	update_ui()

func style_button(btn: Button, is_selected: bool) -> void:
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(4)
	style.set_content_margin_all(4)

	if is_selected:
		style.bg_color = Color(0.2, 0.6, 0.3)
		style.border_color = Color(0.3, 0.8, 0.4)
		btn.add_theme_color_override("font_color", Color.WHITE)
	else:
		style.bg_color = Color(0.25, 0.25, 0.32)
		style.border_color = Color(0.35, 0.35, 0.45)
		btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))

	style.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

func style_card(panel: PanelContainer, is_selected: bool) -> void:
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	style.bg_color = Color(0.12, 0.12, 0.18)

	if is_selected:
		style.border_color = Color(0.3, 0.8, 0.4)
		style.set_border_width_all(2)
	else:
		style.border_color = Color(0.25, 0.25, 0.32)
		style.set_border_width_all(1)

	panel.add_theme_stylebox_override("panel", style)

func update_ui() -> void:
	selected_label.text = "Party: %d / %d" % [selected.size(), MAX_PARTY]
	confirm_btn.disabled = selected.size() == 0

func _on_confirm_pressed() -> void:
	GameManager.party = selected.duplicate()
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/ui/game_root.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/campaign_select.tscn")
