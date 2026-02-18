class_name ItemData extends Resource

@export var name: String = ""
@export_multiline var description: String = ""
@export var texture: Texture2D

# if true, item_pickup calls use() directly instead of adding to inventory
# set this on coin.tres (and any other item that should never enter inventory)
@export var use_on_pickup: bool = false

@export_category("Item Use Effects")
@export var effects: Array[ItemEffect]

func use() -> bool:
	if effects.size() == 0:
		return false
	for e in effects:
		if e:
			e.use()
	return true
