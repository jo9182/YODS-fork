class_name LootTable extends Resource

const LootEntryScript = preload("res://loot/loot_entry.gd")

# these always drop, every time
@export var guaranteed: Array[Resource]

# how many rolls to make from the random pool
@export var random_rolls: int = 1

# weighted pool -- higher weight entries are more likely to be picked
@export var random_pool: Array[Resource]

# if true, the same entry can be picked more than once in one chest open
@export var allow_duplicates: bool = true


# returns an array of {item_data, quantity} or {gold, quantity} dicts
func roll() -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for entry in guaranteed:
		results.append(_entry_to_dict(entry))

	if random_pool.is_empty() or random_rolls <= 0:
		return results

	var total_weight = 0.0
	for entry in random_pool:
		total_weight += entry.weight

	var remaining_rolls = random_rolls
	var remaining_pool = random_pool.duplicate()

	while remaining_rolls > 0 and not remaining_pool.is_empty():
		var roll = randf() * total_weight
		var cumulative = 0.0
		for entry in remaining_pool:
			cumulative += entry.weight
			if roll <= cumulative:
				results.append(_entry_to_dict(entry))
				if not allow_duplicates:
					remaining_pool.erase(entry)
					total_weight -= entry.weight
				break
		remaining_rolls -= 1

	return results


func _entry_to_dict(entry: Resource) -> Dictionary:
	if entry.is_gold():
		return { "gold": entry.gold_amount * entry.get_quantity() }
	else:
		return { "item_data": entry.item_data, "quantity": entry.get_quantity() }
