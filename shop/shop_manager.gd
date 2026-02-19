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
	if total_listed >= max_listings:
		print("shop is full -- buy more listing slots at the altar")
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


func sell(listing: ShopListing) -> int:
	if not listings.has(listing):
		return -1

	var gold_earned = listing.price

	# tell reputation manager how this sale was priced
	ReputationManager.record_sale(listing.price, listing.item_data.base_value)

	listing.quantity -= 1
	if listing.quantity <= 0:
		listings.erase(listing)
	listings_changed.emit()

	PlayerStats.add_gold(gold_earned)
	return gold_earned
