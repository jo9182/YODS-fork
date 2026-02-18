## ShopManager.gd
## Register this as an autoload in Project > Project Settings > Autoload
## with the name "ShopManager" and path res://shop/shop_manager.gd

extends Node

## Emitted whenever listings are added, removed, or changed
signal listings_changed

## Whether the player is currently inside their shop zone
var in_shop_zone: bool = false

## All currently listed items
var listings: Array[ShopListing] = []


## List one unit of an item for sale at the given price.
## Returns false if the item couldn't be listed (e.g. not found in inventory).
func add_listing(item_data: ItemData, price: int) -> bool:
	# Stack quantity if the same item is already listed
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


## Remove one unit of a listing.
## If quantity reaches zero the listing is removed entirely.
## Pass the inventory so the item can be returned to the player.
func delist(listing: ShopListing, inventory: inventoryData) -> void:
	inventory.addItem(listing.item_data, 1)
	listing.quantity -= 1
	if listing.quantity <= 0:
		listings.erase(listing)
	listings_changed.emit()


## Called when an NPC purchases one unit of a listing.
## Removes the item from the listing and adds coins to the player's inventory.
## Returns the gold earned, or -1 if the sale failed.
func sell(listing: ShopListing, coin_item: ItemData) -> int:
	if not listings.has(listing):
		return -1

	var gold_earned = listing.price
	listing.quantity -= 1
	if listing.quantity <= 0:
		listings.erase(listing)
	listings_changed.emit()

	# Add coins equal to the sale price into the player's inventory
	PlayerManager.INVENTORY_DATA.addItem(coin_item, gold_earned)

	return gold_earned
