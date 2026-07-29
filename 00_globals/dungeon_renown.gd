extends Node

signal renown_changed(total_renown: int, chest_progress: int)
signal chests_replenished(count: int)

const CHEST_REFRESH_THRESHOLD := 10
const CHEST_REFRESH_FRACTION := 0.25

var total_renown := 0
var chest_progress := 0
var replenishable_chests: Array[String] = []


func _ready() -> void:
	SaveManager.game_loaded.connect(_load_save_data)
	call_deferred("_load_save_data")


func record_sale(sale_price: int, base_value: int) -> void:
	if base_value <= 0 or float(sale_price) / float(base_value) > 1.2:
		return
	add_renown(1)


func add_renown(amount: int) -> void:
	if amount <= 0:
		return
	total_renown += amount
	chest_progress += amount
	while chest_progress >= CHEST_REFRESH_THRESHOLD:
		var replenished := _replenish_chests()
		if replenished <= 0:
			break
		chest_progress -= CHEST_REFRESH_THRESHOLD
		chests_replenished.emit(replenished)
	_write_save_data()
	renown_changed.emit(total_renown, chest_progress)


func register_opened_chest(chest_key: String, can_replenish: bool) -> void:
	if can_replenish and not replenishable_chests.has(chest_key):
		replenishable_chests.append(chest_key)
	_write_save_data()


func get_explorer_count() -> int:
	if total_renown >= 30:
		return 3
	if total_renown >= 10:
		return 2
	return 1


func _replenish_chests() -> int:
	var candidates := replenishable_chests.duplicate()
	if candidates.is_empty():
		for value in SaveManager.current_save.get("persistience", []):
			var persistent_key := str(value)
			if persistent_key.ends_with("/Persistence"):
				candidates.append(persistent_key)
	if candidates.is_empty():
		return 0
	candidates.shuffle()
	var requested_count := maxi(1, ceili(float(candidates.size()) * CHEST_REFRESH_FRACTION))
	var persistent_values: Array = SaveManager.current_save.get("persistience", [])
	var refreshed_count := 0
	for index in range(mini(requested_count, candidates.size())):
		var chest_key: String = candidates[index]
		if persistent_values.has(chest_key):
			persistent_values.erase(chest_key)
			refreshed_count += 1
			replenishable_chests.erase(chest_key)
	SaveManager.current_save["persistience"] = persistent_values
	return refreshed_count


func _load_save_data() -> void:
	var saved_data: Dictionary = SaveManager.current_save.get("dungeon_renown", {})
	total_renown = int(saved_data.get("total_renown", 0))
	chest_progress = int(saved_data.get("chest_progress", 0))
	replenishable_chests = []
	for chest_key in saved_data.get("replenishable_chests", []):
		replenishable_chests.append(str(chest_key))


func _write_save_data() -> void:
	SaveManager.current_save["dungeon_renown"] = {
		"total_renown": total_renown,
		"chest_progress": chest_progress,
		"replenishable_chests": replenishable_chests.duplicate(),
	}
