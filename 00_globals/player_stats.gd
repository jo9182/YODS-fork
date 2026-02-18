extends Node

# fires whenever gold changes so anything displaying it can update
signal gold_changed(new_amount: int)

# just a number. how much gold the player has.
# way simpler than storing coins as inventory items
var gold: int = 0 : set = _set_gold


# setter so gold_changed always fires when gold is touched
func _set_gold(value: int) -> void:
	gold = value
	gold_changed.emit(gold)


# call this whenever the player earns gold
func add_gold(amount: int) -> void:
	gold += amount


# call this to spend gold -- returns false if they can't afford it
# so you can check before actually spending
func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	return true


# just a helper so you don't have to do the comparison yourself
func can_afford(amount: int) -> bool:
	return gold >= amount
