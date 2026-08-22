extends Node

signal commissions_changed
signal commission_completed(commission_id: String)

const MAX_OPEN_COMMISSIONS := 3
const SAVE_VERSION := 4
const CUSTOMER_VISITS_PER_COMMISSION := 5
const COMMISSION_POOL: Array[Dictionary] = [
	{
		"id": "campfire_supplies",
		"faction_id": "commoners",
		"requester_name": "The Lower Stair Carters",
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
		"faction_id": "reagent_circle",
		"requester_name": "The Reagent Circle",
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
		"faction_id": "commoners",
		"requester_name": "The First Landing Workers",
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
		"id": "landing_lanterns",
		"faction_id": "commoners",
		"requester_name": "The Lower Stair Carters",
		"title": "Landing Lanterns",
		"description": "Workers need enough light to move supplies through the first landing.",
		"requirements": [
			{"item_path": "res://items/torch.tres", "amount": 3},
			{"item_path": "res://items/apple.tres", "amount": 2},
		],
		"area": 1,
		"reward": 46,
		"renown": 1,
	},
	{
		"id": "masonry_repair",
		"faction_id": "craftsfolk",
		"requester_name": "The Stonecutters' Circle",
		"title": "Masonry Repair",
		"description": "A damaged route needs stone and light before the next hauling run.",
		"requirements": [
			{"item_path": "res://items/stone.tres", "amount": 5},
			{"item_path": "res://items/torch.tres", "amount": 2},
		],
		"area": 2,
		"reward": 78,
		"renown": 2,
	},
	{
		"id": "volatile_culture",
		"faction_id": "reagent_circle",
		"requester_name": "The Reagent Circle",
		"title": "Volatile Culture",
		"description": "The Circle needs residue and medicine for a sample that will not stay still.",
		"requirements": [
			{"item_path": "res://items/slime_residue.tres", "amount": 3},
			{"item_path": "res://items/potion.tres", "amount": 1},
		],
		"area": 2,
		"reward": 75,
		"renown": 2,
	},
	{
		"id": "vault_trophy",
		"faction_id": "patron_houses",
		"requester_name": "House Voss",
		"title": "Vault Trophy",
		"description": "A patron wants a presentable treasure recovered from below the first routes.",
		"requirements": [
			{"item_path": "res://items/gem.tres", "amount": 1},
			{"item_path": "res://items/vamp_tooth.tres", "amount": 1},
		],
		"area": 3,
		"reward": 150,
		"renown": 3,
	},
	{
		"id": "escort_provisions",
		"faction_id": "patron_houses",
		"requester_name": "The Voss Escort",
		"title": "Escort Provisions",
		"description": "An escorted expedition needs food and a little insurance before it descends.",
		"requirements": [
			{"item_path": "res://items/apple.tres", "amount": 3},
			{"item_path": "res://items/potion.tres", "amount": 1},
		],
		"area": 2,
		"reward": 96,
		"renown": 2,
	},
	{
		"id": "second_floor_survey",
		"faction_id": "expedition_companies",
		"requester_name": "The Lantern Company",
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
		"faction_id": "craftsfolk",
		"requester_name": "The Stonecutters' Circle",
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
		"faction_id": "expedition_companies",
		"requester_name": "The Red Wardens",
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
		"faction_id": "expedition_companies",
		"requester_name": "The Recovery Detail",
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
		"faction_id": "expedition_companies",
		"requester_name": "The Deep Delvers",
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
		"faction_id": "expedition_companies",
		"requester_name": "The Silent Watch",
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
		"faction_id": "expedition_companies",
		"requester_name": "The Last Light Company",
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


func record_customer_visit(faction_id: String = "") -> bool:
	if offers.size() >= MAX_OPEN_COMMISSIONS:
		return false
	customer_visits_since_offer += 1
	if customer_visits_since_offer < CUSTOMER_VISITS_PER_COMMISSION:
		_write_save_data()
		return false
	var offer := _next_offer(faction_id)
	if offer.is_empty():
		_write_save_data()
		return false
	customer_visits_since_offer = 0
	offers.append(offer)
	var shop_log := get_node_or_null("/root/ShopLog")
	if shop_log != null:
		shop_log.call("record_commission_offered", offer)
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
	var shop_log := get_node_or_null("/root/ShopLog")
	if shop_log != null:
		shop_log.call("record_commission_completed", commission)
	var faction_manager := get_node_or_null("/root/FactionManager")
	if faction_manager != null:
		faction_manager.call("record_commission_completed", str(commission.get("faction_id", "")))
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
				offers.append(_normalize_offer(offer))
		active_commission_id = str(saved_data.get("active_id", ""))
		next_offer_index = int(saved_data.get("next_offer_index", 0))
		customer_visits_since_offer = int(saved_data.get("customer_visits_since_offer", 0))
	if _get_offer_index(active_commission_id) == -1:
		active_commission_id = ""


func _next_offer(faction_id: String = "") -> Dictionary:
	for _attempt in COMMISSION_POOL.size():
		var pool_index: int = posmod(next_offer_index, COMMISSION_POOL.size())
		next_offer_index += 1
		var candidate: Dictionary = COMMISSION_POOL[pool_index].duplicate(true)
		if not faction_id.is_empty() and str(candidate.get("faction_id", "")) != faction_id:
			continue
		if not _is_area_known(int(candidate.get("area", 0))):
			continue
		if _get_offer_index(str(candidate.get("id", ""))) == -1:
			return candidate
	return {}


func _normalize_offer(saved_offer: Dictionary) -> Dictionary:
	var saved_id := str(saved_offer.get("id", ""))
	for pool_offer: Dictionary in COMMISSION_POOL:
		if str(pool_offer.get("id", "")) == saved_id:
			var normalized := pool_offer.duplicate(true)
			normalized.merge(saved_offer, true)
			return normalized
	return saved_offer.duplicate(true)


func _is_area_known(area: int) -> bool:
	if area <= 0:
		return true
	var discovery := get_node_or_null("/root/MapDiscoveryManager")
	if discovery == null:
		return true
	return not MapDiscoveryManager.get_discovered_rooms(area).is_empty()


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
	SaveManager.autosave_game()
