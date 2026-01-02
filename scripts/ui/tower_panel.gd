extends PanelContainer
class_name TowerPanel

var current_tower: BaseTower = null
var pending_move_index: int = -1  # Which pending move we're learning

# UI elements (created in code)
var name_label: Label
var level_label: Label
var xp_bar: ProgressBar
var moves_container: VBoxContainer
var pending_section: VBoxContainer
var close_btn: Button

func _ready() -> void:
	build_ui()
	GameManager.tower_selected.connect(_on_tower_selected)
	GameManager.tower_deselected.connect(_on_tower_deselected)
	visible = false

func build_ui() -> void:
	custom_minimum_size = Vector2(220, 0)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18)
	style.set_border_width_all(2)
	style.border_color = Color(0.3, 0.3, 0.4)
	style.set_content_margin_all(12)
	add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)

	# Header with close button
	var header = HBoxContainer.new()
	vbox.add_child(header)

	name_label = Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	header.add_child(name_label)

	close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(28, 28)
	close_btn.pressed.connect(_on_close_pressed)
	header.add_child(close_btn)

	# Level + XP
	level_label = Label.new()
	level_label.add_theme_font_size_override("font_size", 12)
	level_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(level_label)

	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(0, 8)
	xp_bar.show_percentage = false
	var xp_style = StyleBoxFlat.new()
	xp_style.bg_color = Color(0.2, 0.2, 0.3)
	xp_bar.add_theme_stylebox_override("background", xp_style)
	var xp_fill = StyleBoxFlat.new()
	xp_fill.bg_color = Color(0.3, 0.7, 1.0)
	xp_bar.add_theme_stylebox_override("fill", xp_fill)
	vbox.add_child(xp_bar)

	# Moves section
	var moves_title = Label.new()
	moves_title.text = "MOVES"
	moves_title.add_theme_font_size_override("font_size", 11)
	moves_title.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(moves_title)

	moves_container = VBoxContainer.new()
	moves_container.add_theme_constant_override("separation", 6)
	vbox.add_child(moves_container)

	# Pending moves section
	pending_section = VBoxContainer.new()
	pending_section.add_theme_constant_override("separation", 6)
	pending_section.visible = false
	vbox.add_child(pending_section)

func _on_tower_selected(tower: Node2D) -> void:
	if tower is BaseTower:
		current_tower = tower as BaseTower
		refresh_ui()
		visible = true
		tower.show_range_indicator()

func _on_tower_deselected() -> void:
	if current_tower:
		current_tower.hide_range_indicator()
	current_tower = null
	pending_move_index = -1
	visible = false

func _on_close_pressed() -> void:
	GameManager.deselect_tower()

func refresh_ui() -> void:
	if not current_tower or not current_tower.caught_pokemon:
		return

	var caught = current_tower.caught_pokemon
	var species = GameManager.get_species(caught.species_id)

	# Update header
	name_label.text = species.display_name if species else caught.species_id
	level_label.text = "Level %d" % caught.level
	xp_bar.value = caught.get_xp_progress() * 100

	# Clear and rebuild moves
	for child in moves_container.get_children():
		child.queue_free()

	# Show 4 move slots
	for i in 4:
		var move_btn = create_move_slot(i, caught)
		moves_container.add_child(move_btn)

	# Pending moves
	refresh_pending_section(caught)

func create_move_slot(index: int, caught: CaughtPokemon) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 36)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(4)
	style.set_content_margin_all(6)

	if index < caught.known_moves.size():
		var move_id = caught.known_moves[index]
		var move = GameManager.get_move(move_id)
		if move:
			btn.text = move.display_name
			style.bg_color = get_type_color(move.move_type).darkened(0.5)
			style.border_color = get_type_color(move.move_type)
		else:
			btn.text = move_id
			style.bg_color = Color(0.25, 0.25, 0.3)
			style.border_color = Color(0.4, 0.4, 0.5)
	else:
		btn.text = "—"
		style.bg_color = Color(0.15, 0.15, 0.2)
		style.border_color = Color(0.25, 0.25, 0.3)

	style.set_border_width_all(2)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_color_override("font_color", Color.WHITE)

	# If we're learning a pending move, make slots clickable
	if pending_move_index >= 0 and index < caught.known_moves.size():
		btn.pressed.connect(_on_move_slot_clicked.bind(index))

	return btn

func refresh_pending_section(caught: CaughtPokemon) -> void:
	# Clear existing
	for child in pending_section.get_children():
		child.queue_free()

	if not caught.has_pending_moves():
		pending_section.visible = false
		return

	pending_section.visible = true

	# Title
	var title = Label.new()
	title.text = "NEW MOVE AVAILABLE!"
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	pending_section.add_child(title)

	# Show pending moves
	for i in caught.pending_moves.size():
		var move_id = caught.pending_moves[i]
		var move = GameManager.get_move(move_id)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 6)
		pending_section.add_child(hbox)

		var learn_btn = Button.new()
		learn_btn.text = move.display_name if move else move_id
		learn_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		learn_btn.custom_minimum_size = Vector2(0, 32)

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.5, 0.3)
		style.border_color = Color(0.3, 0.7, 0.4)
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		learn_btn.add_theme_stylebox_override("normal", style)
		learn_btn.add_theme_stylebox_override("hover", style)
		learn_btn.add_theme_color_override("font_color", Color.WHITE)
		learn_btn.pressed.connect(_on_learn_pressed.bind(i))
		hbox.add_child(learn_btn)

		var skip_btn = Button.new()
		skip_btn.text = "Skip"
		skip_btn.custom_minimum_size = Vector2(50, 32)
		skip_btn.pressed.connect(_on_skip_pressed.bind(i))
		hbox.add_child(skip_btn)

	# Instructions if learning
	if pending_move_index >= 0:
		var hint = Label.new()
		hint.text = "Click a move to replace"
		hint.add_theme_font_size_override("font_size", 10)
		hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pending_section.add_child(hint)

func _on_learn_pressed(pending_idx: int) -> void:
	pending_move_index = pending_idx
	refresh_ui()

func _on_skip_pressed(pending_idx: int) -> void:
	if current_tower and current_tower.caught_pokemon:
		current_tower.caught_pokemon.skip_pending_move(pending_idx)
		pending_move_index = -1
		refresh_ui()

func _on_move_slot_clicked(slot_index: int) -> void:
	if current_tower and current_tower.caught_pokemon and pending_move_index >= 0:
		current_tower.caught_pokemon.learn_pending_move(pending_move_index, slot_index)
		pending_move_index = -1
		refresh_ui()

func get_type_color(ptype: GameManager.PokemonType) -> Color:
	match ptype:
		GameManager.PokemonType.FIRE: return Color(1.0, 0.5, 0.2)
		GameManager.PokemonType.WATER: return Color(0.3, 0.6, 1.0)
		GameManager.PokemonType.GRASS: return Color(0.4, 0.8, 0.3)
		GameManager.PokemonType.ELECTRIC: return Color(1.0, 0.9, 0.2)
		GameManager.PokemonType.GROUND: return Color(0.8, 0.6, 0.3)
		GameManager.PokemonType.ROCK: return Color(0.6, 0.5, 0.4)
		GameManager.PokemonType.FLYING: return Color(0.6, 0.7, 1.0)
		GameManager.PokemonType.BUG: return Color(0.6, 0.8, 0.2)
		_: return Color(0.7, 0.7, 0.7)

func _process(_delta: float) -> void:
	# Refresh XP bar in real-time if tower is selected
	if visible and current_tower and current_tower.caught_pokemon:
		var caught = current_tower.caught_pokemon
		xp_bar.value = caught.get_xp_progress() * 100
		level_label.text = "Level %d" % caught.level

		# Check if pending moves changed
		if caught.has_pending_moves() and not pending_section.visible:
			refresh_ui()
