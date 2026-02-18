## ShopManager.gd
## register this as an autoload in Project > Project Settings > Autoload
## name: ShopManager, path: res://shop/shop_manager.gd

extends Node

# fires whenever something gets listed, delisted, or sold
signal listings_changed

# true when the player is standing in their shop zone
# inventory slots use this to know whether to list or use items
var in_shop_zone: bool = false

# everything currently up for sale
var listings: Array[ShopListing] = []


# list one unit of an item for sale at the given price
# stacks quantity if the same item is already listed
func add_listing(item_data: ItemData, price: int) -> bool:
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


# remove one unit of a listing and return the item to the player's inventory
func delist(listing: ShopListing, inventory: inventoryData) -> void:
	inventory.addItem(listing.item_data, 1)
	listing.quantity -= 1
	if listing.quantity <= 0:
		listings.erase(listing)
	listings_changed.emit()


# called when an npc buys something
# removes the item from listings and adds gold to PlayerStats
# returns how much gold was earned, or -1 if something went wrong
func sell(listing: ShopListing) -> int:
	if not listings.has(listing):
		return -1

	var gold_earned = listing.price
	listing.quantity -= 1
	if listing.quantity <= 0:
		listings.erase(listing)
	listings_changed.emit()

	# just add to the gold int, no more messing with coin inventory
	PlayerStats.add_gold(gold_earned)

	return gold_earned
