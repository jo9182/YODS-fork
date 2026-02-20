## Register as autoload: ShopLog
## path: res://shop/shop_log.gd
extends Node

const MAX_ENTRIES = 100

var entries: Array[Dictionary] = []

signal log_updated


func record(item_name: String, price: int, buyer: String) -> void:
	entries.append({
		"item_name": item_name,
		"price": price,
		"buyer": buyer,
	})
	# trim oldest entries if we exceed the cap
	if entries.size() > MAX_ENTRIES:
		entries = entries.slice(entries.size() - MAX_ENTRIES)
	log_updated.emit()


func total_earned() -> int:
	var total = 0
	for e in entries:
		total += e["price"]
	return total


func get_save_data() -> Array:
	return entries


func load_save_data(data: Array) -> void:
	entries = []
	for e in data:
		entries.append(e)
