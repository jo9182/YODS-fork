class_name LootEntry extends Resource

# leave item_data blank to drop gold instead
@export var item_data: ItemData

# only used if item_data is blank
@export var gold_amount: int = 5

# relative weight vs other entries in the same table (higher = more likely)
@export var weight: float = 1.0

@export var quantity_min: int = 1
@export var quantity_max: int = 1

func get_quantity() -> int:
	return randi_range(quantity_min, quantity_max)

func is_gold() -> bool:
	return item_data == null
