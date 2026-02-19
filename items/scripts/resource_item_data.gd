class_name ItemData extends Resource

@export var name: String = ""
@export_multiline var description: String = ""
@export var texture: Texture2D

# the item's fair market value in gold -- used by ReputationManager
# to judge whether the player is pricing fairly.
# set this on every item .tres you want reputation to track.
# leave at 0 to have sales of this item not affect reputation at all.
@export var base_value: int = 0

# if true, item_pickup calls use() directly instead of adding to inventory
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
