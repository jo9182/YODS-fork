class_name Inventory_Slot_UI extends Button

const PICKUP = preload("res://items/item_pickup/item_pickup.tscn")

var slot_data: slotData : set = set_slot_data
@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label

# track the active popup so we only ever have one open
var _popup: PopupMenu = null


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
	_show_action_popup()


# ---------------------------------------------------------------
# Action popup
# ---------------------------------------------------------------

func _show_action_popup() -> void:
	# close any existing popup first
	if _popup:
		_popup.queue_free()

	_popup = PopupMenu.new()
	_popup.process_mode = Node.PROCESS_MODE_ALWAYS

	# build option list depending on context
	_popup.add_item("Use", 0)
	_popup.add_item("Drop", 1)
	if ShopManager.in_shop_zone:
		_popup.add_item("List for Sale", 2)

	get_tree().root.add_child(_popup)
	_popup.id_pressed.connect(_on_popup_id_pressed)
	_popup.popup_hide.connect(_on_popup_hidden)

	# position the popup just below and to the right of the slot
	var slot_rect = get_global_rect()
	_popup.popup(Rect2i(
		int(slot_rect.position.x + slot_rect.size.x),
		int(slot_rect.position.y),
		0, 0))


func _on_popup_id_pressed(id: int) -> void:
	match id:
		0: _do_use()
		1: _do_drop()
		2: _show_list_for_sale_dialog()


func _on_popup_hidden() -> void:
	if _popup:
		_popup.queue_free()
		_popup = null


# ---------------------------------------------------------------
# Actions
# ---------------------------------------------------------------

func _do_use() -> void:
	var was_used = slot_data.item_data.use()
	if was_used == false:
		return
	slot_data.quantity -= 1
	label.text = str(slot_data.quantity)


func _do_drop() -> void:
	var pickup = PICKUP.instantiate()
	pickup.item_data = slot_data.item_data

	var drop_pos = PlayerManager.player.global_position + PlayerManager.player.cardinalDirection * 40
	pickup.global_position = drop_pos

	# disable pickup until the inventory is closed so the player
	# doesn't immediately re-collect it when unpausing
	pickup.get_node("Area2D").monitoring = false
	pickup.get_node("Area2D").monitorable = false

	PlayerManager.player.get_parent().add_child(pickup)

	# re-enable after a short delay -- enough time for the player to
	# close the inventory and move away
	var timer = get_tree().create_timer(1.0, false)
	timer.timeout.connect(func():
		if is_instance_valid(pickup):
			pickup.get_node("Area2D").monitoring = true
			pickup.get_node("Area2D").monitorable = true)

	slot_data.quantity -= 1
	label.text = str(slot_data.quantity)


# ---------------------------------------------------------------
# List for sale dialog (unchanged from before)
# ---------------------------------------------------------------

var _active_price_field: LineEdit = null
var _active_dialog: ConfirmationDialog = null

func _show_list_for_sale_dialog() -> void:
	var dialog = ConfirmationDialog.new()
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	dialog.title = "List for Sale"

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
