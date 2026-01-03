extends Control

const TowerCardScene = preload("res://scenes/ui/tower_card.tscn")

@onready var left_panel: PanelContainer = $MainLayout/LeftPanel
@onready var game_viewport: SubViewportContainer = $MainLayout/GameViewport
@onready var right_panel: PanelContainer = $MainLayout/RightPanel
@onready var sub_viewport: SubViewport = $MainLayout/GameViewport/SubViewport

# Left panel refs
@onready var lives_label: Label = $MainLayout/LeftPanel/VBox/StatsPanel/Stats/LivesLabel
@onready var party_grid: GridContainer = $MainLayout/LeftPanel/VBox/TowerSection/PartyPanel/PartyScroll/PartyGrid
@onready var empty_label: Label = $MainLayout/LeftPanel/VBox/TowerSection/PartyPanel/EmptyLabel

# Right panel refs
@onready var wave_label: Label = $MainLayout/RightPanel/VBox/WavePanel/WaveLabel
@onready var start_wave_btn: Button = $MainLayout/RightPanel/VBox/StartWaveBtn
@onready var enemy_info_panel: PanelContainer = $MainLayout/RightPanel/VBox/EnemyInfoPanel
@onready var enemy_name_label: Label = $MainLayout/RightPanel/VBox/EnemyInfoPanel/VBox/EnemyName
@onready var enemy_health_label: Label = $MainLayout/RightPanel/VBox/EnemyInfoPanel/VBox/EnemyHealth

var tower_panel: TowerPanel
var auto_start_check: CheckBox
var auto_start_enabled: bool = false
var zenny_label: Label

func _ready() -> void:
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.wave_changed.connect(_on_wave_changed)
	GameManager.wave_completed.connect(_on_wave_completed)
	GameManager.game_over.connect(_on_game_over)
	GameManager.enemy_selected.connect(_on_enemy_selected)
	GameManager.pokemon_placed_signal.connect(_on_pokemon_placed)
	GameManager.zenny_changed.connect(_on_zenny_changed)

	_on_lives_changed(GameManager.lives)
	update_wave_label()
	populate_party_towers()
	enemy_info_panel.visible = false
	setup_tower_panel()
	setup_auto_start()
	setup_zenny_display()

func _on_wave_completed() -> void:
	enable_start_button()
	if auto_start_enabled and GameManager.current_wave < GameManager.waves_total:
		# Small delay before auto-starting next wave
		get_tree().create_timer(0.5).timeout.connect(_auto_start_next_wave)

func _auto_start_next_wave() -> void:
	if auto_start_enabled and not GameManager.is_wave_active:
		_on_start_wave_pressed()

func populate_party_towers() -> void:
	# Clear existing
	for child in party_grid.get_children():
		child.queue_free()

	# Party now contains UUIDs of individual Pokemon
	var has_party = GameManager.party.size() > 0
	empty_label.visible = not has_party

	for uuid in GameManager.party:
		var caught = GameManager.get_pokemon_by_uuid(uuid)
		if not caught:
			continue
		var species = GameManager.get_species(caught.species_id)
		if not species:
			continue

		var card = TowerCardScene.instantiate() as TowerCard
		var tower_data = TowerData.new()
		tower_data.tower_id = uuid  # Use uuid as unique identifier
		tower_data.display_name = caught.get_display_name() + " Lv." + str(caught.level)
		tower_data.pokemon_type = species.pokemon_type
		tower_data.damage = species.base_damage * caught.get_stat_multiplier()
		tower_data.attack_range = species.base_range * caught.get_stat_multiplier()
		tower_data.attack_speed = species.base_attack_speed * caught.get_stat_multiplier()
		if species.tower_scene:
			tower_data.scene = species.tower_scene
		tower_data.icon = species.icon
		card.set_tower_data(tower_data)
		card.caught_pokemon = caught

		# Disable card if already placed (1:1 placement)
		if GameManager.is_pokemon_placed(uuid):
			card.set_placed(true)

		party_grid.add_child(card)

func _on_lives_changed(amount: int) -> void:
	lives_label.text = "♥ %d" % amount

func _on_wave_changed(_wave: int) -> void:
	update_wave_label()

func _on_pokemon_placed(uuid: String) -> void:
	# Find and update the tower card for this Pokemon
	for card in party_grid.get_children():
		if card is TowerCard and card.caught_pokemon and card.caught_pokemon.uuid == uuid:
			card.set_placed(true)
			break

func update_wave_label() -> void:
	wave_label.text = "Wave %d / %d" % [GameManager.current_wave, GameManager.waves_total]

func _on_start_wave_pressed() -> void:
	if not GameManager.is_wave_active:
		GameManager.start_wave()
		start_wave_btn.disabled = true

func _on_game_over(won: bool) -> void:
	start_wave_btn.disabled = true
	# Award Zenny for completing the run
	var zenny_reward = 0
	if won:
		zenny_reward = 500 + GameManager.current_wave * 100
		GameManager.add_zenny(zenny_reward)
		# Mark map as completed
		if GameManager.selected_map:
			GameManager.complete_map(GameManager.selected_map.get_id())

	# Show result popup
	show_game_over_popup(won, zenny_reward)

func show_game_over_popup(won: bool, zenny: int) -> void:
	# Darken background
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# Center container
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var popup = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.98)
	style.set_border_width_all(3)
	style.border_color = Color(1, 0.85, 0.2) if won else Color(0.8, 0.2, 0.2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(30)
	popup.add_theme_stylebox_override("panel", style)
	center.add_child(popup)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	popup.add_child(vbox)

	var title = Label.new()
	title.text = "VICTORY!" if won else "DEFEAT"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2) if won else Color(0.8, 0.2, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	if won and zenny > 0:
		var reward = Label.new()
		reward.text = "+%d Zenny" % zenny
		reward.add_theme_font_size_override("font_size", 18)
		reward.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
		reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(reward)

	var btn = Button.new()
	btn.text = "Continue"
	btn.custom_minimum_size = Vector2(120, 40)
	btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/campaign_select.tscn"))
	vbox.add_child(btn)

func _on_enemy_selected(enemy: Node) -> void:
	enemy_info_panel.visible = true
	enemy_name_label.text = enemy.enemy_name if "enemy_name" in enemy else "Enemy"
	enemy_health_label.text = "HP: %d / %d" % [enemy.hp, enemy.max_hp] if "hp" in enemy else "HP: ?"

func enable_start_button() -> void:
	if GameManager.current_wave < GameManager.waves_total:
		start_wave_btn.disabled = false

func _on_back_pressed() -> void:
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_ball_selected(ball_id: String) -> void:
	GameManager.selected_ball = ball_id

func setup_tower_panel() -> void:
	tower_panel = TowerPanel.new()
	# Add to right panel's VBox, after the spacer
	var right_vbox = right_panel.get_node("VBox")
	right_vbox.add_child(tower_panel)
	# Move before enemy info panel
	right_vbox.move_child(tower_panel, enemy_info_panel.get_index())

func setup_auto_start() -> void:
	# Add checkbox below start wave button
	auto_start_check = CheckBox.new()
	auto_start_check.text = "Auto Start"
	auto_start_check.add_theme_font_size_override("font_size", 12)
	auto_start_check.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	auto_start_check.toggled.connect(_on_auto_start_toggled)

	var right_vbox = right_panel.get_node("VBox")
	# Insert after start wave button
	var btn_idx = start_wave_btn.get_index()
	right_vbox.add_child(auto_start_check)
	right_vbox.move_child(auto_start_check, btn_idx + 1)

func _on_auto_start_toggled(enabled: bool) -> void:
	auto_start_enabled = enabled

func setup_zenny_display() -> void:
	# Add Zenny label to stats panel
	var stats = left_panel.get_node("VBox/StatsPanel/Stats")
	zenny_label = Label.new()
	zenny_label.add_theme_font_size_override("font_size", 14)
	zenny_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))  # Gold
	stats.add_child(zenny_label)
	_on_zenny_changed(GameManager.zenny)

func _on_zenny_changed(amount: int) -> void:
	if zenny_label:
		zenny_label.text = "Z %d" % amount
