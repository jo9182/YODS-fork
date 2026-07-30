class_name slotData extends Resource

@export var item_data : ItemData
@export var quantity : int = 0 : set = set_quantity

func set_quantity(value : int) ->void:
	quantity = value
	emit_changed()
