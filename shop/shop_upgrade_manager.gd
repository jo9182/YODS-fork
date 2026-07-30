extends Node

signal upgrades_changed

const UPGRADES := [
	{
		"id": "shelf_expansion",
		"name": "Shelf Expansion",
		"cost": 75,
		"description": "+3 listed item slots.",
	},
	{
		"id": "hanging_sign",
		"name": "Hanging Sign",
		"cost": 120,
		"description": "Customers arrive 25% faster.",
	},
	{
		"id": "display_case",
		"name": "Display Case",
		"cost": 180,
		"description": "Customers carry 25% more gold.",
	},
]

var purchased: Dictionary = {}


func _ready() -> void:
	SaveManager.game_loaded.connect(_load_from_save)
	call_deferred("_load_from_save")


func get_upgrades() -> Array:
	return UPGRADES


func is_purchased(upgrade_id: String) -> bool:
	return purchased.has(upgrade_id)


func purchase(upgrade_id: String) -> bool:
	var upgrade: Dictionary = get_upgrade(upgrade_id)
	if upgrade.is_empty() or is_purchased(upgrade_id):
		return false
	var cost: int = int(upgrade.get("cost", 0))
	if not PlayerStats.spend_gold(cost):
		return false
	purchased[upgrade_id] = true
	_store_in_save()
	upgrades_changed.emit()
	SaveManager.save_game()
	return true


func get_upgrade(upgrade_id: String) -> Dictionary:
	for entry in UPGRADES:
		var upgrade: Dictionary = entry
		if str(upgrade.get("id", "")) == upgrade_id:
			return upgrade
	return {}


func get_listing_capacity(base_capacity: int = 5) -> int:
	return base_capacity + (3 if is_purchased("shelf_expansion") else 0)


func get_customer_spawn_multiplier() -> float:
	return 0.75 if is_purchased("hanging_sign") else 1.0


func get_customer_budget_multiplier() -> float:
	return 1.25 if is_purchased("display_case") else 1.0


func get_save_data() -> Array:
	return purchased.keys()


func load_save_data(data: Array) -> void:
	purchased.clear()
	for value in data:
		var upgrade_id: String = str(value)
		if not get_upgrade(upgrade_id).is_empty():
			purchased[upgrade_id] = true
	upgrades_changed.emit()


func _load_from_save() -> void:
	var saved_upgrades: Array = SaveManager.current_save.get("shop_upgrades", [])
	load_save_data(saved_upgrades)


func _store_in_save() -> void:
	SaveManager.current_save["shop_upgrades"] = get_save_data()
