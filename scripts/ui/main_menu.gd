extends Control

@onready var title: Label = $Content/LogoSection/LogoHBox/Title
@onready var slots_section: HBoxContainer = $Content/SlotsSection
@onready var import_btn: Button = $Content/ButtonsSection/ImportBtn
@onready var export_btn: Button = $Content/ButtonsSection/ExportBtn
@onready var editor_btn: Button = $Content/ButtonsSection/MapEditorBtn
@onready var confirm_dialog: ConfirmationDialog = $ConfirmDialog

var pulse_tween: Tween
var pending_delete_slot: int = -1
var pending_import: bool = false

func _ready() -> void:
	style_ui()
	refresh_slots()
	start_animations()

func style_ui() -> void:
	# Style save slot cards
	for i in range(slots_section.get_child_count()):
		var panel = slots_section.get_child(i) as PanelContainer
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(1, 1, 1, 0.95)
		panel_style.set_corner_radius_all(12)
		panel_style.set_border_width_all(3)
		panel_style.border_color = Color(0.2, 0.3, 0.5)
		panel_style.set_content_margin_all(12)
		panel.add_theme_stylebox_override("panel", panel_style)

		var play_btn = panel.get_node("VBox/PlayBtn")
		style_button_green(play_btn)

		var delete_btn = panel.get_node("VBox/DeleteBtn")
		style_button_red(delete_btn)

	# Bottom buttons
	style_button_neutral(import_btn)
	style_button_neutral(export_btn)
	style_button_neutral(editor_btn)

func style_button_green(btn: Button) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.7, 0.35)
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	style.border_color = Color(0.2, 0.5, 0.25)
	btn.add_theme_stylebox_override("normal", style)

	var hover = style.duplicate()
	hover.bg_color = Color(0.35, 0.8, 0.4)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed = style.duplicate()
	pressed.bg_color = Color(0.25, 0.6, 0.3)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)

func style_button_red(btn: Button) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.7, 0.3, 0.3)
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	style.border_color = Color(0.5, 0.2, 0.2)
	btn.add_theme_stylebox_override("normal", style)

	var hover = style.duplicate()
	hover.bg_color = Color(0.8, 0.35, 0.35)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed = style.duplicate()
	pressed.bg_color = Color(0.6, 0.25, 0.25)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)

func style_button_neutral(btn: Button) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.95, 0.98)
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	style.border_color = Color(0.3, 0.4, 0.5)
	btn.add_theme_stylebox_override("normal", style)

	var hover = style.duplicate()
	hover.bg_color = Color(0.88, 0.9, 0.95)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed = style.duplicate()
	pressed.bg_color = Color(0.8, 0.82, 0.88)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_color_override("font_color", Color(0.15, 0.2, 0.3))
	btn.add_theme_color_override("font_hover_color", Color(0.1, 0.15, 0.25))

func refresh_slots() -> void:
	for i in range(SaveManager.NUM_SLOTS):
		var slot_panel = slots_section.get_child(i)
		var info = SaveManager.get_slot_info(i)
		update_slot_panel(slot_panel, i, info)

func update_slot_panel(panel: PanelContainer, slot: int, info: Dictionary) -> void:
	var header = panel.get_node("VBox/Header")
	var sprite = panel.get_node("VBox/Sprite")
	var starter_label = panel.get_node("VBox/StarterLabel")
	var details_label = panel.get_node("VBox/DetailsLabel")
	var play_btn = panel.get_node("VBox/PlayBtn")
	var delete_btn = panel.get_node("VBox/DeleteBtn")

	# Dark text for white cards
	header.add_theme_color_override("font_color", Color(0.2, 0.25, 0.35))
	starter_label.add_theme_color_override("font_color", Color(0.15, 0.2, 0.3))
	details_label.add_theme_color_override("font_color", Color(0.4, 0.45, 0.55))

	header.text = "Slot %d" % (slot + 1)

	if info.get("empty", true):
		starter_label.text = "Empty"
		details_label.text = "New Game"
		sprite.visible = false
		delete_btn.visible = false
		play_btn.text = "New Game"
	else:
		var starter = info.get("starter", "???")
		var count = info.get("pokemon_count", 0)
		starter_label.text = starter.capitalize()
		details_label.text = "%d Pokemon" % count
		delete_btn.visible = true
		play_btn.text = "Continue"

		# Try to load starter sprite
		sprite.visible = true
		var sprite_path = "res://assets/sprites/%s/icon.png" % starter
		if ResourceLoader.exists(sprite_path):
			sprite.texture = load(sprite_path)

	if not play_btn.pressed.is_connected(_on_slot_pressed):
		play_btn.pressed.connect(_on_slot_pressed.bind(slot))
	if not delete_btn.pressed.is_connected(_on_delete_pressed):
		delete_btn.pressed.connect(_on_delete_pressed.bind(slot))

func _on_slot_pressed(slot: int) -> void:
	SaveManager.load_slot(slot)
	if GameManager.starter_pokemon == "":
		get_tree().change_scene_to_file("res://scenes/ui/starter_select.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/campaign_select.tscn")

func _on_delete_pressed(slot: int) -> void:
	pending_delete_slot = slot
	pending_import = false
	confirm_dialog.dialog_text = "Delete Slot %d?\nThis cannot be undone." % (slot + 1)
	confirm_dialog.popup_centered()

func _on_confirm_dialog_confirmed() -> void:
	if pending_import:
		if SaveManager.import_from_file():
			refresh_slots()
	elif pending_delete_slot >= 0:
		SaveManager.delete_slot(pending_delete_slot)
		pending_delete_slot = -1
		refresh_slots()

func _on_export_pressed() -> void:
	if SaveManager.current_slot < 0:
		for i in range(SaveManager.NUM_SLOTS):
			if SaveManager.slot_exists(i):
				SaveManager.current_slot = i
				break

	if SaveManager.current_slot >= 0 and SaveManager.export_to_file():
		confirm_dialog.dialog_text = "Exported to:\n%s" % SaveManager.get_export_path()
		confirm_dialog.get_ok_button().text = "OK"
		confirm_dialog.popup_centered()

func _on_import_pressed() -> void:
	if not FileAccess.file_exists(SaveManager.get_export_path()):
		confirm_dialog.dialog_text = "No import file found at:\n%s" % SaveManager.get_export_path()
		confirm_dialog.popup_centered()
		return

	var target_slot = 0
	for i in range(SaveManager.NUM_SLOTS):
		if not SaveManager.slot_exists(i):
			target_slot = i
			break

	SaveManager.current_slot = target_slot
	pending_import = true
	pending_delete_slot = -1
	confirm_dialog.dialog_text = "Import save to Slot %d?" % (target_slot + 1)
	confirm_dialog.popup_centered()

func start_animations() -> void:
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(title, "modulate:a", 0.9, 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(title, "modulate:a", 1.0, 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _on_map_editor_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/map_select.tscn")
