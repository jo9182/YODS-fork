extends Node

# fires whenever gold changes so anything displaying it can update
signal gold_changed(new_amount: int)

# how much gold the player has
var gold: int = 0 : set = _set_gold

# skill bonuses, start at zero, skills add to these
var speed_bonus: float = 0.0
var damage_bonus: float = 0.0
var lantern_energy_bonus: float = 0.0
var lantern_scale_bonus: float = 0.0
var customer_spawn_reduction: float = 0.0
var customer_budget_bonus: float = 0.0
var fair_sale_renown_bonus: int = 0
var explorer_bonus: int = 0


func _set_gold(value: int) -> void:
	gold = value
	gold_changed.emit(gold)


func add_gold(amount: int) -> void:
	gold += amount


# returns false if they can't afford it so you can check before spending
func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	return true


func can_afford(amount: int) -> bool:
	return gold >= amount
