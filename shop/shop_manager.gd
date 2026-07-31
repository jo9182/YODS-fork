## register as autoload: ShopManager
## path: res://shop/shop_manager.gd

extends Node

signal listings_changed

var in_shop_zone: bool = false
var listings: Array[ShopListing] = []
var max_listings: int = 5


func add_listing(item_data: ItemData, price: int) -> bool:
	var total_listed = 0
	for l in listings:
		total_listed += l.quantity
	if total_listed >= ShopUpgradeManager.get_listing_capacity(max_listings):
		print("shop is full -- buy more display space at the workshop")
		return false

	for listing in listings:
		if listing.item_data == item_data:
			listing.quantity += 1
			listings_changed.emit()
			return true

	var new_listing = ShopListing.new()
	new_listing.item_data = item_data
	new_listing.price = price
	new_listing.quantity = 1
	listings.append(new_listing)
	listings_changed.emit()
	return true


func delist(listing: ShopListing, inventory: inventoryData) -> void:
	inventory.addItem(listing.item_data, 1)
	listing.quantity -= 1
	if listing.quantity <= 0:
		listings.erase(listing)
	listings_changed.emit()


# buyer_name is shown in the shop log, pass the NPC's priest_name
func sell(listing: ShopListing, buyer_name: String = "Unknown", buyer_faction: String = "") -> int:
	if not listings.has(listing):
		return -1

	var gross_sale := listing.price
	var loan_payment := TaxDebtManager.record_shop_sale(gross_sale)
	var gold_earned := gross_sale - loan_payment

	ReputationManager.record_sale(gross_sale, listing.item_data.base_value)
	if not buyer_faction.is_empty():
		var faction_manager := get_node_or_null("/root/FactionManager")
		if faction_manager != null:
			faction_manager.call("record_purchase", buyer_faction, gross_sale, listing.item_data.base_value)
	var dungeon_renown := get_node_or_null("/root/DungeonRenown")
	if dungeon_renown != null:
		dungeon_renown.call("record_sale", gross_sale, listing.item_data.base_value)
	ShopLog.record(listing.item_data.name, gold_earned, buyer_name, gross_sale, loan_payment, buyer_faction)
	if loan_payment > 0:
		ShopLog.record_debt_event("Loan payment made after the sale.", loan_payment, TaxDebtManager.loan_balance)

	listing.quantity -= 1
	if listing.quantity <= 0:
		listings.erase(listing)
	listings_changed.emit()

	PlayerStats.add_gold(gold_earned)
	TaxDebtManager.consider_misfortune(PlayerStats.gold)
	return gold_earned
