## registered as autoload: ShopManager

extends Node

signal listings_changed

var in_shop_zone: bool = false
var listings: Array[ShopListing] = []

# default listing cap -- skill upgrades add to this
var max_listings: int = 5


func add_listing(item_data: ItemData, price: int) -> bool:
	# check the cap before adding anything new
	var total_listed = 0
	for l in listings:
		total_listed += l.quantity
	if total_listed >= max_listings:
		print("shop is full -- buy more listing slots at the altar")
		return false

	# stack quantity if the same item is already listed
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


# remove one unit of a listing and return it to the player's inventory
func delist(listing: ShopListing, inventory: inventoryData) -> void:
	inventory.addItem(listing.item_data, 1)
	listing.quantity -= 1
	if listing.quantity <= 0:
		listings.erase(listing)
	listings_changed.emit()


# called when an npc buys something
# removes the item and pays the player in gold
func sell(listing: ShopListing) -> int:
	if not listings.has(listing):
		return -1

	var gold_earned = listing.price
	listing.quantity -= 1
	if listing.quantity <= 0:
		listings.erase(listing)
	listings_changed.emit()

	PlayerStats.add_gold(gold_earned)
	return gold_earned
