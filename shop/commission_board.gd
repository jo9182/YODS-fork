extends CanvasLayer

var is_open := false

@onready var gold_label: Label = $Control/Panel/GoldLabel
@onready var status_label: Label = $Control/Panel/StatusLabel
@onready var commission_rows: VBoxContainer = $Control/Panel/CommissionRows


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	CommissionManager.commissions_changed.connect(_refresh)
	PlayerStats.gold_changed.connect(_on_gold_changed)
	PlayerManager.INVENTORY_DATA.changed.connect(_refresh)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("commission"):
		if is_open:
			close()
		elif ShopManager.in_shop_zone and not InventoryMenu.is_paused and not _is_workshop_open():
			open()
		else:
			return
		get_viewport().set_input_as_handled()
		return
	if not is_open:
		return
	if event.is_action_pressed("craft") or event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	if not ShopManager.in_shop_zone or _is_workshop_open():
		return
	is_open = true
	visible = true
	get_tree().paused = true
	PauseMenu.process_mode = Node.PROCESS_MODE_DISABLED
	_refresh()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	get_tree().paused = false
	PauseMenu.process_mode = Node.PROCESS_MODE_ALWAYS


func _refresh() -> void:
	if not is_open:
		return
	gold_label.text = "Gold: %d" % PlayerStats.gold
	var active: Dictionary = CommissionManager.get_active_commission()
	if active.is_empty() and CommissionManager.get_offers().is_empty():
		status_label.text = "No requests yet. Visiting customers may leave commissions."
	elif active.is_empty():
		status_label.text = "Choose one commission. Deliver it here when ready."
	else:
		status_label.text = "Active: %s" % str(active.get("title", "Commission"))
	_clear_rows()
	for commission: Dictionary in CommissionManager.get_offers():
		_add_commission_row(commission, active)


func _add_commission_row(commission: Dictionary, active: Dictionary) -> void:
	var commission_id: String = str(commission.get("id", ""))
	var item_data := CommissionManager.get_item_data(commission)
	var item_name := item_data.name if item_data != null else "Items"
	var amount: int = int(commission.get("amount", 0))
	var reward: int = int(commission.get("reward", 0))
	var renown: int = int(commission.get("renown", 0))
	var button := Button.new()
	button.custom_minimum_size = Vector2(420.0, 40.0)
	button.add_theme_font_size_override("font_size", 9)
	if active.is_empty():
		button.text = "ACCEPT: %s - bring %d %s\nReward: %dg + %d renown" % [
			str(commission.get("title", "Commission")), amount, item_name, reward, renown,
		]
	elif commission_id == str(active.get("id", "")):
		var progress: Dictionary = CommissionManager.get_progress(commission)
		var current_amount: int = int(progress.get("current", 0))
		var target_amount: int = int(progress.get("target", amount))
		button.text = "TURN IN: %s - %d/%d %s\nReward: %dg + %d renown" % [
			str(commission.get("title", "Commission")), current_amount, target_amount, item_name, reward, renown,
		]
		button.disabled = current_amount < target_amount
	else:
		button.text = "%s - bring %d %s\nFinish the active commission first." % [
			str(commission.get("title", "Commission")), amount, item_name,
		]
		button.disabled = true
	button.pressed.connect(_on_commission_pressed.bind(commission_id))
	commission_rows.add_child(button)


func _clear_rows() -> void:
	for child in commission_rows.get_children():
		child.queue_free()


func _on_commission_pressed(commission_id: String) -> void:
	if CommissionManager.active_commission_id == commission_id:
		CommissionManager.turn_in_active()
	else:
		CommissionManager.accept(commission_id)
	_refresh()


func _on_gold_changed(_new_amount: int) -> void:
	_refresh()


func _is_workshop_open() -> bool:
	var workshop: Node = get_node_or_null("/root/WorkshopMenu")
	return workshop != null and bool(workshop.get("is_open"))
