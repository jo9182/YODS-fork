extends Node

signal faction_changed(faction_id: String, score: int)

const SAVE_VERSION := 1
const SCORE_MIN := -100
const SCORE_MAX := 100
const FACTIONS := {
	"commoners": {
		"display_name": "Commoners",
		"description": "Workers, scavengers, and families who use the safer dungeon routes.",
	},
	"craftsfolk": {
		"display_name": "Craftsfolk",
		"description": "Smiths and builders who descend for ore, gems, and salvage.",
	},
	"reagent_circle": {
		"display_name": "Reagent Circle",
		"description": "Alchemists who harvest unusual materials from below.",
	},
	"patron_houses": {
		"display_name": "Patron Houses",
		"description": "Wealthy sponsors seeking relics, trophies, and dangerous diversions.",
	},
	"expedition_companies": {
		"display_name": "Expedition Companies",
		"description": "Adventurers using the shop as a resupply point between delves.",
	},
}

var faction_scores: Dictionary = {}
var encountered_factions: Dictionary = {}
var event_log: Array[String] = []


func _ready() -> void:
	for faction_id in FACTIONS:
		faction_scores[faction_id] = 0
		encountered_factions[faction_id] = false
	if SaveManager != null:
		SaveManager.game_loaded.connect(_load_from_save)
	call_deferred("_load_from_save")


func get_faction_ids() -> Array[String]:
	var ids: Array[String] = []
	for faction_id in FACTIONS:
		ids.append(faction_id)
	return ids


func get_known_faction_ids() -> Array[String]:
	var ids: Array[String] = []
	for faction_id in FACTIONS:
		if bool(encountered_factions.get(faction_id, false)):
			ids.append(faction_id)
	return ids


func is_valid_faction(faction_id: String) -> bool:
	return FACTIONS.has(faction_id)


func get_display_name(faction_id: String) -> String:
	return str(FACTIONS.get(faction_id, {}).get("display_name", faction_id))


func get_description(faction_id: String) -> String:
	return str(FACTIONS.get(faction_id, {}).get("description", ""))


func get_score(faction_id: String) -> int:
	return int(faction_scores.get(faction_id, 0))


func get_relationship_label(faction_id: String) -> String:
	var score := get_score(faction_id)
	if score < -50:
		return "Avoiding"
	if score < -15:
		return "Wary"
	if score < 20:
		return "Known"
	if score < 60:
		return "Trusted"
	return "Favored"


func get_visit_weight(faction_id: String) -> float:
	if not is_valid_faction(faction_id):
		return 1.0
	var score := get_score(faction_id)
	if score < -50:
		return 0.35
	if score < -15:
		return 0.7
	if score < 20:
		return 1.0
	if score < 60:
		return 1.15
	return 1.3


func record_customer_visit(faction_id: String) -> void:
	if not is_valid_faction(faction_id):
		return
	if bool(encountered_factions.get(faction_id, false)):
		return
	encountered_factions[faction_id] = true
	_record_event("The %s have begun using the dungeon shop." % get_display_name(faction_id))
	_write_save_data()
	faction_changed.emit(faction_id, get_score(faction_id))


func record_purchase(faction_id: String, sale_price: int, base_value: int) -> void:
	if not is_valid_faction(faction_id) or base_value <= 0:
		return
	var ratio := float(sale_price) / float(base_value)
	if ratio <= 1.0:
		adjust_standing(faction_id, 2)
	elif ratio <= 1.2:
		adjust_standing(faction_id, 1)
	elif ratio <= 1.6:
		adjust_standing(faction_id, -1)
	else:
		adjust_standing(faction_id, -2)


func record_commission_completed(faction_id: String) -> void:
	if is_valid_faction(faction_id):
		adjust_standing(faction_id, 8)


func record_adventurer_harm(killed: bool) -> void:
	if killed:
		adjust_standing("expedition_companies", -12)
	else:
		adjust_standing("expedition_companies", -4)


func adjust_standing(faction_id: String, amount: int) -> void:
	if not is_valid_faction(faction_id) or amount == 0:
		return
	var old_score := get_score(faction_id)
	var old_label := get_relationship_label(faction_id)
	var new_score := clampi(old_score + amount, SCORE_MIN, SCORE_MAX)
	faction_scores[faction_id] = new_score
	var new_label := get_relationship_label(faction_id)
	if old_label != new_label:
		_record_event("The %s now regard the shop as %s." % [get_display_name(faction_id), new_label])
	_write_save_data()
	faction_changed.emit(faction_id, new_score)


func get_recent_events(max_count: int = 4) -> Array[String]:
	var count := mini(max_count, event_log.size())
	var recent: Array[String] = []
	for index in range(event_log.size() - count, event_log.size()):
		recent.append(event_log[index])
	return recent


func get_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"scores": faction_scores.duplicate(),
		"encountered": encountered_factions.duplicate(),
		"events": event_log.duplicate(),
	}


func load_save_data(data: Dictionary) -> void:
	for faction_id in FACTIONS:
		faction_scores[faction_id] = clampi(int(data.get("scores", {}).get(faction_id, 0)), SCORE_MIN, SCORE_MAX)
		encountered_factions[faction_id] = bool(data.get("encountered", {}).get(faction_id, false))
	event_log.clear()
	for event in data.get("events", []):
		event_log.append(str(event))
	if event_log.size() > 8:
		event_log = event_log.slice(event_log.size() - 8)


func _load_from_save() -> void:
	if SaveManager == null:
		return
	load_save_data(SaveManager.current_save.get("factions", {}))


func _record_event(message: String) -> void:
	event_log.append(message)
	while event_log.size() > 8:
		event_log.pop_front()
	var shop_log := get_node_or_null("/root/ShopLog")
	if shop_log != null:
		shop_log.call("record_faction_event", "", message)


func _write_save_data() -> void:
	if SaveManager != null:
		SaveManager.current_save["factions"] = get_save_data()
