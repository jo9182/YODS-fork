extends Node

signal commissions_changed
signal commission_completed(commission_id: String)

const MAX_OPEN_COMMISSIONS := 3
const SAVE_VERSION := 2
const COMMISSION_POOL: Array[Dictionary] = [
	{
		"id": "stone_stockpile",
		"title": "Mason's Stockpile",
		"description": "A visiting mason needs stone for safer campfires.",
		"item_path": "res://items/stone.tres",
		"amount": 6,
		"reward": 28,
		"renown": 1,
	},
	{
		"id": "slime_research",
		"title": "Slime Research",
		"description": "An alchemist wants fresh residue from the dungeon.",
		"item_path": "res://items/slime_residue.tres",
		"amount": 5,
		"reward": 38,
		"renown": 1,
	},
	{
		"id": "torch_crate",
		"title": "Torch Crate",
		"description": "Supply the next expedition with a stack of torches.",
		"item_path": "res://items/torch.tres",
		"amount": 4,
		"reward": 24,
		"renown": 1,
	},
	{
		"id": "healer_reserve",
		"title": "Healer's Reserve",
		"description": "A visiting medic needs a fresh emergency potion reserve.",
		"item_path": "res://items/potion.tres",
		"amount": 2,
		"reward": 65,
		"renown": 2,
	},
	{
		"id": "vampire_proof",
		"title": "Vampire Proof",
		"description": "A wary party is buying vampire teeth as trophies.",
		"item_path": "res://items/vamp_tooth.tres",
		"amount": 3,
		"reward": 54,
		"renown": 2,
	},
	{
		"id": "gem_delivery",
		"title": "Gem Courier",
		"description": "A visiting collector will pay to secure a rare dungeon gem.",
		"item_path": "res://items/gem.tres",
		"amount": 1,
		"reward": 90,
		"renown": 3,
	},
]

var offers: Array[Dictionary] = []
var active_commission_id := ""
var next_offer_index := 0


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
	var item_path: String = str(commission.get("item_path", ""))
	return load(item_path) as ItemData


func get_progress(commission: Dictionary) -> Dictionary:
	var item_data := get_item_data(commission)
	var target_amount: int = int(commission.get("amount", 0))
	var current_amount := 0
	if item_data != null:
		current_amount = PlayerManager.INVENTORY_DATA.get_item_count(item_data)
	return {"current": current_amount, "target": target_amount}


func record_customer_visit() -> bool:
	if offers.size() >= MAX_OPEN_COMMISSIONS:
		return false
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
	var item_data := get_item_data(commission)
	var amount: int = int(commission.get("amount", 0))
	if item_data == null or not PlayerManager.INVENTORY_DATA.remove_item(item_data, amount):
		return false
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
	var saved_data: Dictionary = SaveManager.current_save.get("commissions", {})
	if int(saved_data.get("version", 0)) >= SAVE_VERSION:
		var saved_offers: Array = saved_data.get("offers", [])
		for offer: Dictionary in saved_offers:
			if not str(offer.get("id", "")).is_empty():
				offers.append(offer.duplicate(true))
		active_commission_id = str(saved_data.get("active_id", ""))
		next_offer_index = int(saved_data.get("next_offer_index", 0))
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
	}
	SaveManager.save_game()
