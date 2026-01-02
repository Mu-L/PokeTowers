extends Resource
class_name MoveData

enum Category { PHYSICAL, SPECIAL, STATUS }

@export var id: String = ""
@export var display_name: String = ""
@export var move_type: GameManager.PokemonType = GameManager.PokemonType.NORMAL
@export var category: Category = Category.PHYSICAL
@export var power: int = 40  # 0 for status moves
@export var accuracy: int = 100  # 0-100
