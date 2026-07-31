extends Node

signal commissions_changed
signal commission_completed(commission_id: String)

const MAX_OPEN_COMMISSIONS := 3
const SAVE_VERSION := 3
const CUSTOMER_VISITS_PER_COMMISSION := 5
const COMMISSION_POOL: Array[Dictionary] = [
	{
		"id": "campfire_supplies",
		"title": "Campfire Supplies",
		"description": "A caravan wants a compact bundle for its first descent.",
		"requirements": [
			{"item_path": "res://items/stone.tres", "amount": 4},
			{"item_path": "res://items/torch.tres", "amount": 2},
		],
		"area": 1,
		"reward": 42,
		"renown": 1,
	},
	{
		"id": "slime_specimens",
		"title": "Slime Specimens",
		"description": "An alchemist needs a properly packed sample crate.",
		"requirements": [
			{"item_path": "res://items/slime_residue.tres", "amount": 4},
			{"item_path": "res://items/stone.tres", "amount": 2},
		],
		"area": 1,
		"reward": 52,
		"renown": 1,
	},
	{
		"id": "field_rations",
		"title": "Field Rations",
		"description": "A cautious party wants food and medicine before going below.",
		"requirements": [
			{"item_path": "res://items/apple.tres", "amount": 3},
			{"item_path": "res://items/potion.tres", "amount": 1},
		],
		"area": 1,
		"reward": 48,
		"renown": 1,
	},
	{
		"id": "second_floor_survey",
		"title": "Second Floor Survey",
		"description": "A mapmaker needs proof that a route into Area 2 is viable.",
		"requirements": [
			{"item_path": "res://items/torch.tres", "amount": 4},
			{"item_path": "res://items/slime_residue.tres", "amount": 2},
		],
		"area": 2,
		"reward": 70,
		"renown": 2,
	},
	{
		"id": "artisan_shipment",
		"title": "Artisan's Shipment",
		"description": "A craftsperson needs sturdy stone and a cut gem from Area 2.",
		"requirements": [
			{"item_path": "res://items/stone.tres", "amount": 4},
			{"item_path": "res://items/gem.tres", "amount": 1},
		],
		"area": 2,
		"reward": 86,
		"renown": 2,
	},
	{
		"id": "vampire_hunter_kit",
		"title": "Vampire Hunter's Kit",
		"description": "A hunter wants trophies and medicine from the deeper rooms.",
		"requirements": [
			{"item_path": "res://items/vamp_tooth.tres", "amount": 3},
			{"item_path": "res://items/potion.tres", "amount": 2},
		],
		"area": 3,
		"reward": 98,
		"renown": 2,
	},
	{
		"id": "recovery_detail",
		"title": "Recovery Detail",
		"description": "A rescue party wants supplies after a survey of Area 3.",
		"requirements": [
			{"item_path": "res://items/slime_residue.tres", "amount": 3},
			{"item_path": "res://items/potion.tres", "amount": 2},
			{"item_path": "res://items/torch.tres", "amount": 2},
		],
		"area": 3,
		"reward": 112,
		"renown": 3,
	},
	{
		"id": "deep_delver_cache",
		"title": "Deep Delver Cache",
		"description": "An expedition is stocking up for an Area 4 push.",
		"requirements": [
			{"item_path": "res://items/gem.tres", "amount": 1},
			{"item_path": "res://items/torch.tres", "amount": 5},
			{"item_path": "res://items/stone.tres", "amount": 3},
		],
		"area": 4,
		"reward": 140,
		"renown": 3,
	},
	{
		"id": "silent_watch",
		"title": "Silent Watch",
		"description": "A sentry company is preparing to hold an Area 4 doorway.",
		"requirements": [
			{"item_path": "res://items/torch.tres", "amount": 4},
			{"item_path": "res://items/vamp_tooth.tres", "amount": 2},
		],
		"area": 4,
		"reward": 132,
		"renown": 3,
	},
	{
		"id": "last_light_relay",
		"title": "Last Light Relay",
		"description": "Someone is paying well to prepare a route into the final dark.",
		"requirements": [
			{"item_path": "res://items/torch.tres", "amount": 6},
			{"item_path": "res://items/gem.tres", "amount": 1},
			{"item_path": "res://items/vamp_tooth.tres", "amount": 2},
		],
		"area": 5,
		"reward": 190,
		"renown": 4,
	},
]

var offers: Array[Dictionary] = []
var active_commission_id := ""
var next_offer_index := 0
var customer_visits_since_offer := 0


func _ready() -> void:
	SaveManager.game_loaded.connect(_load_from_save)
	_load_from_save()


func get_offers() -> Array[Dictionary]:
	return offers


func get_active_commission() -> Dictionary:
	if active_commission_id.is_empty():
		return {}
	for offer: Dictionary in offers:
		if str(offer.get("id", "")) == active_commission_id:
			return offer
	return {}


func get_item_data(commission: Dictionary) -> ItemData:
	var requirements := get_requirements(commission)
	if requirements.is_empty():
		return null
	var item_path: String = str(requirements[0].get("item_path", ""))
	return load(item_path) as ItemData


func get_requirements(commission: Dictionary) -> Array[Dictionary]:
	var requirements: Array[Dictionary] = []
	var saved_requirements = commission.get("requirements", [])
	if saved_requirements is Array:
		for entry in saved_requirements:
			if entry is Dictionary:
				var item_path: String = str(entry.get("item_path", ""))
				var amount: int = int(entry.get("amount", 0))
				if not item_path.is_empty() and amount > 0:
					requirements.append({"item_path": item_path, "amount": amount})
	if not requirements.is_empty():
		return requirements
	var legacy_item_path: String = str(commission.get("item_path", ""))
	var legacy_amount: int = int(commission.get("amount", 0))
	if not legacy_item_path.is_empty() and legacy_amount > 0:
		requirements.append({"item_path": legacy_item_path, "amount": legacy_amount})
	return requirements


func get_area_requirement(commission: Dictionary) -> int:
	return clampi(int(commission.get("area", 0)), 0, 5)


func get_progress(commission: Dictionary) -> Dictionary:
	var requirement_progress: Array[Dictionary] = []
	var is_complete := true
	for requirement in get_requirements(commission):
		var item_data: ItemData = load(str(requirement.get("item_path", ""))) as ItemData
		var target_amount: int = int(requirement.get("amount", 0))
		var current_amount := 0
		if item_data != null:
			current_amount = PlayerManager.INVENTORY_DATA.get_item_count(item_data)
		if item_data == null or current_amount < target_amount:
			is_complete = false
		requirement_progress.append({
			"item_name": item_data.name if item_data != null else "Unknown item",
			"current": current_amount,
			"target": target_amount,
		})
	var area: int = get_area_requirement(commission)
	var area_complete := area == 0 or not MapDiscoveryManager.get_discovered_rooms(area).is_empty()
	if not area_complete:
		is_complete = false
	return {
		"requirements": requirement_progress,
		"area": area,
		"area_complete": area_complete,
		"complete": is_complete,
	}


func get_requirements_text(commission: Dictionary, include_progress: bool = false) -> String:
	var labels: Array[String] = []
	var progress: Dictionary = get_progress(commission)
	for entry in progress.get("requirements", []):
		var requirement: Dictionary = entry
		var item_name: String = str(requirement.get("item_name", "Items"))
		var target_amount: int = int(requirement.get("target", 0))
		if include_progress:
			labels.append("%d/%d %s" % [int(requirement.get("current", 0)), target_amount, item_name])
		else:
			labels.append("%dx %s" % [target_amount, item_name])
	var area: int = int(progress.get("area", 0))
	if area > 0:
		var area_label := "Area %d surveyed" % area
		if include_progress:
			area_label = "%s: %s" % [area_label, "yes" if bool(progress.get("area_complete", false)) else "no"]
		labels.append(area_label)
	return ", ".join(labels)


func record_customer_visit() -> bool:
	if offers.size() >= MAX_OPEN_COMMISSIONS:
		return false
	customer_visits_since_offer += 1
	if customer_visits_since_offer < CUSTOMER_VISITS_PER_COMMISSION:
		_write_save_data()
		return false
	customer_visits_since_offer = 0
	offers.append(_next_offer())
	_write_save_data()
	commissions_changed.emit()
	return true


func accept(commission_id: String) -> bool:
	if not active_commission_id.is_empty() or _get_offer_index(commission_id) == -1:
		return false
	active_commission_id = commission_id
	_write_save_data()
	commissions_changed.emit()
	return true


func turn_in_active() -> bool:
	var commission: Dictionary = get_active_commission()
	if commission.is_empty():
		return false
	var progress: Dictionary = get_progress(commission)
	if not bool(progress.get("complete", false)):
		return false
	for requirement in get_requirements(commission):
		var item_data: ItemData = load(str(requirement.get("item_path", ""))) as ItemData
		if item_data == null:
			return false
		PlayerManager.INVENTORY_DATA.remove_item(item_data, int(requirement.get("amount", 0)))
	PlayerStats.add_gold(int(commission.get("reward", 0)))
	DungeonRenown.add_renown(int(commission.get("renown", 0)))
	var completed_id := active_commission_id
	var offer_index := _get_offer_index(completed_id)
	active_commission_id = ""
	if offer_index >= 0:
		offers.remove_at(offer_index)
	_write_save_data()
	commission_completed.emit(completed_id)
	commissions_changed.emit()
	return true


func _load_from_save() -> void:
	offers.clear()
	active_commission_id = ""
	next_offer_index = 0
	customer_visits_since_offer = 0
	var saved_data: Dictionary = SaveManager.current_save.get("commissions", {})
	if int(saved_data.get("version", 0)) >= 2:
		var saved_offers: Array = saved_data.get("offers", [])
		for offer: Dictionary in saved_offers:
			if not str(offer.get("id", "")).is_empty():
				offers.append(offer.duplicate(true))
		active_commission_id = str(saved_data.get("active_id", ""))
		next_offer_index = int(saved_data.get("next_offer_index", 0))
		customer_visits_since_offer = int(saved_data.get("customer_visits_since_offer", 0))
	if _get_offer_index(active_commission_id) == -1:
		active_commission_id = ""


func _next_offer() -> Dictionary:
	for _attempt in COMMISSION_POOL.size():
		var pool_index: int = posmod(next_offer_index, COMMISSION_POOL.size())
		next_offer_index += 1
		var candidate: Dictionary = COMMISSION_POOL[pool_index].duplicate(true)
		if _get_offer_index(str(candidate.get("id", ""))) == -1:
			return candidate
	var fallback_index: int = posmod(next_offer_index, COMMISSION_POOL.size())
	next_offer_index += 1
	return COMMISSION_POOL[fallback_index].duplicate(true)


func _get_offer_index(commission_id: String) -> int:
	if commission_id.is_empty():
		return -1
	for index in offers.size():
		if str(offers[index].get("id", "")) == commission_id:
			return index
	return -1


func _write_save_data() -> void:
	SaveManager.current_save["commissions"] = {
		"version": SAVE_VERSION,
		"offers": offers.duplicate(true),
		"active_id": active_commission_id,
		"next_offer_index": next_offer_index,
		"customer_visits_since_offer": customer_visits_since_offer,
	}
	SaveManager.save_game()
