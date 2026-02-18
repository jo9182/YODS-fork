class_name shop_interact extends Area2D

@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var control: Control = $CanvasLayer/Control
@onready var button: Button = $CanvasLayer/Control/Button
@onready var item_list: ItemList = $CanvasLayer/Control/ItemList

# Held so the confirm/cancel callbacks know which listing was clicked
var _pending_delist: ShopListing = null


func _ready() -> void:
	ShopManager.listings_changed.connect(_refresh_display)


func _on_body_entered(_body: Node2D) -> void:
	button.visible = true
	ShopManager.in_shop_zone = true


func _on_body_exited(_body: Node2D) -> void:
	button.visible = false
	item_list.visible = false
	ShopManager.in_shop_zone = false


func _on_button_pressed() -> void:
	button.visible = false
	_refresh_display()
	item_list.visible = true


## Rebuild the ItemList from whatever ShopManager currently has listed.
func _refresh_display() -> void:
	item_list.clear()

	if ShopManager.listings.is_empty():
		item_list.add_item("[ No items listed for sale ]")
		return

	for listing in ShopManager.listings:
		var label = "%s  —  %d gold  (x%d)" % [
			listing.item_data.name,
			listing.price,
			listing.quantity
		]
		item_list.add_item(label, listing.item_data.texture)


## Connect this to the ItemList's "item_clicked" signal in the editor.
func _on_item_list_item_clicked(index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
	if ShopManager.listings.is_empty():
		return

	_pending_delist = ShopManager.listings[index]

	var dialog = ConfirmationDialog.new()
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	dialog.title = "Delist Item"
	dialog.dialog_text = "Remove '%s' from your shop and return it to your inventory?" % _pending_delist.item_data.name
	get_tree().root.add_child(dialog)
	dialog.popup_centered(Vector2(260, 0))

	dialog.confirmed.connect(_on_delist_confirmed.bind(dialog))
	dialog.canceled.connect(_on_dialog_canceled.bind(dialog))


func _on_delist_confirmed(dialog: ConfirmationDialog) -> void:
	if _pending_delist != null:
		# PlayerManager.INVENTORY_DATA is the preloaded player_inventory.tres — no @export needed
		ShopManager.delist(_pending_delist, PlayerManager.INVENTORY_DATA)
		_pending_delist = null
	dialog.queue_free()


func _on_dialog_canceled(dialog: ConfirmationDialog) -> void:
	_pending_delist = null
	dialog.queue_free()
