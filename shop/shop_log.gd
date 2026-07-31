## Register as autoload: ShopLog
## path: res://shop/shop_log.gd
extends Node

const MAX_SALES := 100
const MAX_EVENTS := 250
const SAVE_VERSION := 2

var entries: Array[Dictionary] = []
var events: Array[Dictionary] = []

signal log_updated


func record(item_name: String, price: int, buyer: String, gross_price: int = -1, tax_payment: int = 0, faction_id: String = "") -> void:
	var sale := {
		"type": "sale",
		"item_name": item_name,
		"price": price,
		"buyer": buyer,
		"gross_price": price if gross_price < 0 else gross_price,
		"tax_payment": tax_payment,
		"faction_id": faction_id,
	}
	entries.append(sale)
	_trim_entries()
	_append_event(sale)


func record_visitor(visitor_name: String, customer_type: String, faction_id: String = "") -> void:
	_append_event({
		"type": "visitor",
		"visitor_name": visitor_name,
		"customer_type": customer_type,
		"faction_id": faction_id,
		"message": "Visited the shop.",
	})


func record_faction_event(faction_id: String, message: String) -> void:
	_append_event({
		"type": "faction",
		"faction_id": faction_id,
		"message": message,
	})


func record_commission_offered(commission: Dictionary) -> void:
	_record_commission_event(commission, "offered")


func record_commission_completed(commission: Dictionary) -> void:
	_record_commission_event(commission, "completed")


func record_dungeon_event(message: String, subtype: String = "activity", amount: int = 0) -> void:
	_append_event({
		"type": "dungeon",
		"subtype": subtype,
		"message": message,
		"amount": amount,
	})


func record_debt_event(message: String, amount: int = 0, balance: int = -1) -> void:
	_append_event({
		"type": "debt",
		"message": message,
		"amount": amount,
		"balance": balance,
	})


func total_earned() -> int:
	var total := 0
	for entry in entries:
		total += int(entry.get("price", 0))
	return total


func get_events_by_type(event_type: String) -> Array[Dictionary]:
	return get_events_by_types([event_type])


func get_events_by_types(event_types: Array[String]) -> Array[Dictionary]:
	var matching: Array[Dictionary] = []
	for event in events:
		if event_types.has(str(event.get("type", ""))):
			matching.append(event)
	return matching


func get_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"entries": entries.duplicate(true),
		"events": events.duplicate(true),
	}


func load_save_data(data: Variant) -> void:
	entries.clear()
	events.clear()
	if data is Array:
		_load_entries(data)
	elif data is Dictionary:
		_load_entries(data.get("entries", []))
		var saved_events = data.get("events", [])
		if saved_events is Array:
			for event in saved_events:
				if event is Dictionary:
					events.append(event.duplicate(true))
	if events.is_empty():
		for entry in entries:
			events.append(entry.duplicate(true))
	_trim_entries()
	_trim_events()
	log_updated.emit()


func _record_commission_event(commission: Dictionary, status: String) -> void:
	_append_event({
		"type": "commission",
		"status": status,
		"commission_id": str(commission.get("id", "")),
		"title": str(commission.get("title", commission.get("name", "Commission"))),
		"requester_name": str(commission.get("requester_name", "A customer")),
		"faction_id": str(commission.get("faction_id", "")),
		"area": int(commission.get("area", 0)),
		"reward": int(commission.get("reward", 0)),
	})


func _append_event(event: Dictionary) -> void:
	events.append(event)
	_trim_events()
	log_updated.emit()


func _load_entries(saved_entries: Array) -> void:
	for entry in saved_entries:
		if entry is Dictionary:
			entries.append(entry.duplicate(true))


func _trim_entries() -> void:
	if entries.size() > MAX_SALES:
		entries = entries.slice(entries.size() - MAX_SALES)


func _trim_events() -> void:
	if events.size() > MAX_EVENTS:
		events = events.slice(events.size() - MAX_EVENTS)
