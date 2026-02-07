extends Control

@onready var dock_container: HBoxContainer = $CenterContainer/VBox/DockContainer
@onready var collection_grid: GridContainer = $CenterContainer/VBox/ScrollContainer/CollectionGrid
@onready var party_label: Label = $CenterContainer/VBox/PartyLabel
@onready var zenny_label: Label = $WalletPill/ZennyLabel
@onready var upgrade_btn: Button = $CenterContainer/VBox/UpgradeBtn
@onready var confirm_btn: Button = $CenterContainer/VBox/HBox/ConfirmBtn

var selected: Array[String] = []  # UUIDs in party
var dock_slots: Array[Control] = []  # Slot containers
var collection_cards: Dictionary = {}  # uuid -> card

const SLOT_SIZE := Vector2(100, 120)
const CARD_SIZE := Vector2(100, 130)
const ANIM_DURATION := 0.2

func _ready() -> void:
	create_dock_slots()
	populate_collection()
	update_ui()

# ===== DOCK SLOTS =====

func create_dock_slots() -> void:
	for child in dock_container.get_children():
		child.queue_free()
	dock_slots.clear()

	# Show all slots up to party_size_limit, plus one locked slot if upgradeable
	var show_locked = GameManager.get_party_upgrade_cost() >= 0
	var total_slots = GameManager.party_size_limit + (1 if show_locked else 0)

	for i in total_slots:
		var slot = create_dock_slot(i)
		dock_container.add_child(slot)
		dock_slots.append(slot)

func create_dock_slot(index: int) -> PanelContainer:
	var slot = PanelContainer.new()
	slot.custom_minimum_size = SLOT_SIZE

	var is_locked = index >= GameManager.party_size_limit
	slot.set_meta("locked", is_locked)
	slot.set_meta("index", index)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	slot.add_child(vbox)

	if is_locked:
		style_slot_locked(slot)
		# Padlock icon
		var lock_label = Label.new()
		lock_label.text = "🔒"
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_label.add_theme_font_size_override("font_size", 24)
		vbox.add_child(lock_label)
		# Cost label
		var cost_label = Label.new()
		cost_label.text = "%dz" % GameManager.get_party_upgrade_cost()
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_label.add_theme_font_size_override("font_size", 10)
		cost_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		vbox.add_child(cost_label)
		# Click handler
		slot.gui_input.connect(_on_locked_slot_input)
	else:
		style_slot_empty(slot)
		# Plus icon
		var plus_label = Label.new()
		plus_label.name = "PlusLabel"
		plus_label.text = "+"
		plus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plus_label.add_theme_font_size_override("font_size", 32)
		plus_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
		vbox.add_child(plus_label)

	return slot

func style_slot_empty(slot: PanelContainer) -> void:
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.set_content_margin_all(8)
	style.bg_color = Color(0.15, 0.15, 0.2, 0.5)
	style.border_color = Color(0.25, 0.25, 0.32)
	style.set_border_width_all(2)
	slot.add_theme_stylebox_override("panel", style)

func style_slot_locked(slot: PanelContainer) -> void:
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.set_content_margin_all(8)
	style.bg_color = Color(0.1, 0.1, 0.12, 0.8)
	style.border_color = Color(0.2, 0.2, 0.25)
	style.set_border_width_all(2)
	slot.add_theme_stylebox_override("panel", style)

func _on_locked_slot_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cost = GameManager.get_party_upgrade_cost()
		if cost > 0:
			# Simple upgrade - just try it
			if GameManager.upgrade_party_size():
				create_dock_slots()
				update_ui()

# ===== COLLECTION CARDS =====

func populate_collection() -> void:
	for child in collection_grid.get_children():
		child.queue_free()
	collection_cards.clear()

	# Group by species, sort
	var by_species: Dictionary = {}
	for uuid in GameManager.pokedex.keys():
		var caught = GameManager.pokedex[uuid] as CaughtPokemon
		if caught.species_id not in by_species:
			by_species[caught.species_id] = []
		by_species[caught.species_id].append(caught)

	var species_ids = by_species.keys()
	species_ids.sort()

	for species_id in species_ids:
		var pokemon_list = by_species[species_id]
		pokemon_list.sort_custom(func(a, b): return a.catch_number < b.catch_number)

		for caught in pokemon_list:
			var species = GameManager.get_species(caught.species_id)
			if not species:
				continue

			var card = create_collection_card(caught, species)
			collection_grid.add_child(card)
			collection_cards[caught.uuid] = card

func create_collection_card(caught: CaughtPokemon, species: PokemonSpecies) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE
	card.set_meta("uuid", caught.uuid)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)

	# Icon
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if species.icon:
		icon.texture = species.icon
	vbox.add_child(icon)

	# Name
	var name_label = Label.new()
	name_label.text = caught.get_display_name()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.clip_text = true
	vbox.add_child(name_label)

	# Level
	var level_label = Label.new()
	level_label.text = "Lv.%d" % caught.level
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 9)
	level_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(level_label)

	# Stats with icons
	var stats_label = Label.new()
	stats_label.text = "⚔%d 👟%d" % [caught.get_phys_attack(), caught.get_speed()]
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 9)
	stats_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(stats_label)

	# IV star rating
	var rating = caught.get_iv_star_rating()
	var iv_label = Label.new()
	if caught.is_all_perfect():
		iv_label.text = "⭐PERFECT"
		iv_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	else:
		iv_label.text = "★".repeat(rating) + "☆".repeat(5 - rating)
		iv_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.4) if rating >= 4 else Color(0.45, 0.45, 0.5))
	iv_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	iv_label.add_theme_font_size_override("font_size", 8)
	vbox.add_child(iv_label)

	# Style with type color
	style_collection_card(card, species.get_type_color())

	# Click handler
	card.gui_input.connect(_on_collection_card_input.bind(caught.uuid))

	return card

func style_collection_card(card: PanelContainer, type_color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(6)
	style.set_content_margin_all(6)
	style.bg_color = Color(0.12, 0.12, 0.18)
	style.border_color = type_color.darkened(0.3)
	style.set_border_width_all(3)
	card.add_theme_stylebox_override("panel", style)

func _on_collection_card_input(event: InputEvent, uuid: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		add_to_party(uuid)

# ===== PARTY MANAGEMENT =====

func add_to_party(uuid: String) -> void:
	if uuid in selected:
		return
	if selected.size() >= GameManager.party_size_limit:
		return

	selected.append(uuid)

	# Hide from collection, show in dock
	if uuid in collection_cards:
		var card = collection_cards[uuid]
		animate_to_dock(card, uuid)

	update_ui()

func remove_from_party(uuid: String) -> void:
	if uuid not in selected:
		return

	selected.erase(uuid)

	# Show back in collection
	if uuid in collection_cards:
		var card = collection_cards[uuid]
		animate_to_collection(card)

	refresh_dock_display()
	update_ui()

func animate_to_dock(card: PanelContainer, uuid: String) -> void:
	# Find first empty slot
	var target_slot: Control = null
	for i in range(min(selected.size(), dock_slots.size())):
		if i == selected.size() - 1:  # The newly added slot
			target_slot = dock_slots[i]
			break

	if not target_slot:
		card.visible = false
		refresh_dock_display()
		return

	# Animate card moving up
	var start_pos = card.global_position
	var end_pos = target_slot.global_position

	# Hide original card
	card.visible = false

	# Create flying clone
	var clone = create_flying_card(uuid)
	get_tree().root.add_child(clone)
	clone.global_position = start_pos

	var tween = get_tree().create_tween()
	tween.tween_property(clone, "global_position", end_pos, ANIM_DURATION).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		clone.queue_free()
		refresh_dock_display()
	)

func animate_to_collection(card: PanelContainer) -> void:
	# Just show it again (could add animation later)
	card.visible = true

func create_flying_card(uuid: String) -> PanelContainer:
	var caught = GameManager.pokedex.get(uuid) as CaughtPokemon
	if not caught:
		return PanelContainer.new()

	var species = GameManager.get_species(caught.species_id)
	if not species:
		return PanelContainer.new()

	return create_collection_card(caught, species)

func refresh_dock_display() -> void:
	# Clear dock slot contents and repopulate
	for i in dock_slots.size():
		var slot = dock_slots[i]
		var is_locked = slot.get_meta("locked", false)

		# Disconnect old signals
		for connection in slot.gui_input.get_connections():
			if connection.callable.get_method() == "_on_dock_slot_input":
				slot.gui_input.disconnect(connection.callable)

		# Clear children
		for child in slot.get_children():
			child.queue_free()

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		slot.add_child(vbox)

		if is_locked:
			style_slot_locked(slot)
			var lock_label = Label.new()
			lock_label.text = "🔒"
			lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock_label.add_theme_font_size_override("font_size", 24)
			vbox.add_child(lock_label)
			var cost_label = Label.new()
			cost_label.text = "%dz" % GameManager.get_party_upgrade_cost()
			cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cost_label.add_theme_font_size_override("font_size", 10)
			cost_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
			vbox.add_child(cost_label)
		elif i < selected.size():
			# Filled slot
			var uuid = selected[i]
			var caught = GameManager.pokedex.get(uuid) as CaughtPokemon
			if caught:
				var species = GameManager.get_species(caught.species_id)
				if species:
					style_slot_filled(slot, species.get_type_color())
					create_dock_card_content(vbox, caught, species)
					slot.gui_input.connect(_on_dock_slot_input.bind(uuid))
		else:
			# Empty slot
			style_slot_empty(slot)
			var plus_label = Label.new()
			plus_label.text = "+"
			plus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			plus_label.add_theme_font_size_override("font_size", 32)
			plus_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
			vbox.add_child(plus_label)

func style_slot_filled(slot: PanelContainer, type_color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.set_content_margin_all(6)
	style.bg_color = Color(0.15, 0.15, 0.22)
	style.border_color = type_color
	style.set_border_width_all(3)
	slot.add_theme_stylebox_override("panel", style)

func create_dock_card_content(vbox: VBoxContainer, caught: CaughtPokemon, species: PokemonSpecies) -> void:
	# Icon
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if species.icon:
		icon.texture = species.icon
	vbox.add_child(icon)

	# Name (short)
	var name_label = Label.new()
	var display = caught.nickname if caught.nickname else species.display_name
	name_label.text = display
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.clip_text = true
	vbox.add_child(name_label)

	# Level
	var level_label = Label.new()
	level_label.text = "Lv.%d" % caught.level
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 8)
	level_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(level_label)

func _on_dock_slot_input(event: InputEvent, uuid: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		remove_from_party(uuid)

# ===== UI UPDATES =====

func update_ui() -> void:
	party_label.text = "ACTIVE PARTY (%d/%d)" % [selected.size(), GameManager.party_size_limit]
	zenny_label.text = "%d" % GameManager.zenny
	confirm_btn.disabled = selected.size() == 0
	update_upgrade_btn()

func update_upgrade_btn() -> void:
	var cost = GameManager.get_party_upgrade_cost()
	if cost < 0:
		upgrade_btn.text = "Party Maxed (%d)" % GameManager.MAX_PARTY_SIZE
		upgrade_btn.disabled = true
		upgrade_btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	else:
		upgrade_btn.text = "+1 Slot (%dz)" % cost
		var can_afford = GameManager.zenny >= cost
		upgrade_btn.disabled = not can_afford
		if can_afford:
			upgrade_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
		else:
			upgrade_btn.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))

func _on_upgrade_pressed() -> void:
	if GameManager.upgrade_party_size():
		create_dock_slots()
		refresh_dock_display()
		update_ui()

func _on_confirm_pressed() -> void:
	GameManager.party = selected.duplicate()
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/ui/game_root.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/campaign_select.tscn")
