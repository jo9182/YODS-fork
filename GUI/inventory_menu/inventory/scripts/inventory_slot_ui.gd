class_name Inventory_Slot_UI extends Button

var slot_data: slotData : set = set_slot_data
@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label


func _ready() -> void:
	texture_rect.texture = null
	label.text = ""
	focus_entered.connect(item_focused)
	focus_exited.connect(item_unfocused)
	pressed.connect(item_pressed)


func set_slot_data(value: slotData) -> void:
	slot_data = value
	if slot_data == null:
		return
	texture_rect.texture = slot_data.item_data.texture
	label.text = str(slot_data.quantity)


func item_focused() -> void:
	if slot_data != null and slot_data.item_data != null:
		var hint = ""
		if ShopManager.in_shop_zone:
			hint = "\n[Click to list for sale]"
		InventoryMenu.update_item_description(slot_data.item_data.description + hint)

func item_unfocused() -> void:
	InventoryMenu.update_item_description("")


func item_pressed() -> void:
	if not slot_data or not slot_data.item_data:
		return

	# If the player is standing in their shop zone, list the item instead of using it
	if ShopManager.in_shop_zone:
		_show_list_for_sale_dialog()
		return

	# Normal use behaviour
	var was_used = slot_data.item_data.use()
	if was_used == false:
		return
	slot_data.quantity -= 1
	label.text = str(slot_data.quantity)


## Opens a dialog asking for a price, then lists the item in the shop.
var _active_price_field: LineEdit = null
var _active_dialog: ConfirmationDialog = null

func _show_list_for_sale_dialog() -> void:
	var dialog = ConfirmationDialog.new()
	# Must be ALWAYS so it works while the tree is paused (inventory pauses the game)
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	dialog.title = "List for Sale"

	# Build a small price-entry UI inside the dialog
	var vbox = VBoxContainer.new()
	vbox.process_mode = Node.PROCESS_MODE_ALWAYS

	var info = Label.new()
	info.text = "Set a price for: %s" % slot_data.item_data.name
	vbox.add_child(info)

	var price_field = LineEdit.new()
	price_field.process_mode = Node.PROCESS_MODE_ALWAYS
	price_field.placeholder_text = "Price in gold (e.g. 250)"
	price_field.set("max_length", 7)
	vbox.add_child(price_field)

	dialog.add_child(vbox)
	get_tree().root.add_child(dialog)
	dialog.popup_centered()

	_active_dialog = dialog
	_active_price_field = price_field

	# Focus the text field automatically
	await get_tree().process_frame
	price_field.grab_focus()

	dialog.confirmed.connect(_on_list_confirmed)
	dialog.canceled.connect(_on_list_canceled)


func _on_list_confirmed() -> void:
	var price = int(_active_price_field.text)
	if price > 0:
		ShopManager.add_listing(slot_data.item_data, price)
		slot_data.quantity -= 1
		label.text = str(slot_data.quantity)
	_active_dialog.queue_free()
	_active_dialog = null
	_active_price_field = null


func _on_list_canceled() -> void:
	_active_dialog.queue_free()
	_active_dialog = null
	_active_price_field = null
