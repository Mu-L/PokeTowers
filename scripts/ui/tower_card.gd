extends PanelContainer
class_name TowerCard

signal deploy_pressed(tower_data: TowerData)

@export var tower_data: TowerData

var caught_pokemon: CaughtPokemon = null  # Set for caught pokemon cards

@onready var icon: TextureRect = $HBox/Icon
@onready var name_label: Label = $HBox/VBox/NameLabel
@onready var type_label: Label = $HBox/VBox/TypeLabel
@onready var deploy_btn: Button = $HBox/DeployBtn

var _placed: bool = false  # For 1:1 placement system

func _ready() -> void:
	if tower_data:
		setup()

func setup() -> void:
	if not tower_data:
		return

	if icon and tower_data.icon:
		icon.texture = tower_data.icon

	if name_label:
		name_label.text = tower_data.display_name

	if type_label:
		type_label.text = tower_data.get_type_name()
		type_label.add_theme_color_override("font_color", tower_data.get_type_color())

func set_tower_data(data: TowerData) -> void:
	tower_data = data
	if is_node_ready():
		setup()

func update_button_state() -> void:
	if deploy_btn:
		deploy_btn.disabled = _placed
	modulate = Color(0.5, 0.5, 0.5) if _placed else Color.WHITE

func set_placed(placed: bool) -> void:
	_placed = placed
	update_button_state()

func _on_deploy_btn_pressed() -> void:
	if tower_data and not _placed:
		GameManager.select_tower(tower_data.tower_id)
		GameManager.selected_caught_pokemon = caught_pokemon
		deploy_pressed.emit(tower_data)
