class_name ShopLogMenu extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var summary_label: Label = $Panel/MarginContainer/Content/Header/Summary
@onready var close_button: Button = $Panel/MarginContainer/Content/Header/CloseButton
@onready var tabs: TabContainer = $Panel/MarginContainer/Content/Tabs
@onready var sales_log: RichTextLabel = $Panel/MarginContainer/Content/Tabs/Sales
@onready var customers_log: RichTextLabel = $Panel/MarginContainer/Content/Tabs/Customers
@onready var commissions_log: RichTextLabel = $Panel/MarginContainer/Content/Tabs/Commissions
@onready var dungeon_log: RichTextLabel = $Panel/MarginContainer/Content/Tabs/Dungeon
@onready var debt_log: RichTextLabel = $Panel/MarginContainer/Content/Tabs/Debt


func _ready() -> void:
	panel.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_button.pressed.connect(_close)
	ShopLog.log_updated.connect(_refresh)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shop_log"):
		if panel.visible:
			_close()
		else:
			_open()
		get_viewport().set_input_as_handled()


func _open() -> void:
	var menu_manager := get_node_or_null("/root/MenuManager")
	if menu_manager != null:
		menu_manager.call("open", self)
	_refresh()
	panel.visible = true
	get_tree().paused = true


func _close() -> void:
	var menu_manager := get_node_or_null("/root/MenuManager")
	if menu_manager != null:
		menu_manager.call("close", self)
	panel.visible = false
	get_tree().paused = false


func close() -> void:
	_close()


func _refresh() -> void:
	var selected_tab := tabs.current_tab
	var sales := ShopLog.get_events_by_type("sale")
	var customer_events := ShopLog.get_events_by_types(["visitor", "faction"])
	var commission_events := ShopLog.get_events_by_type("commission")
	summary_label.text = "%d sales  |  %dg received  |  %d customers  |  %d commissions" % [sales.size(), ShopLog.total_earned(), customer_events.size(), commission_events.size()]
	sales_log.text = _build_sales_text(sales)
	customers_log.text = _build_customers_text(customer_events)
	commissions_log.text = _build_commissions_text(commission_events)
	dungeon_log.text = _build_dungeon_text(ShopLog.get_events_by_type("dungeon"))
	debt_log.text = _build_debt_text(ShopLog.get_events_by_type("debt"))
	if tabs.get_tab_count() > 0:
		tabs.current_tab = clampi(selected_tab, 0, tabs.get_tab_count() - 1)


func _build_sales_text(sales: Array[Dictionary]) -> String:
	if sales.is_empty():
		return "No sales recorded yet."
	var lines: Array[String] = []
	for index in range(sales.size() - 1, -1, -1):
		var sale := sales[index]
		var line := "[b]Received %dg[/b]  %s\nfrom %s" % [int(sale.get("price", 0)), _safe_text(sale.get("item_name", "Item")), _safe_text(sale.get("buyer", "Unknown buyer"))]
		var tax_payment := int(sale.get("tax_payment", 0))
		if tax_payment > 0:
			line += "  |  Tax paid: %dg" % tax_payment
		lines.append(line)
	return "\n\n".join(lines)


func _build_customers_text(customer_events: Array[Dictionary]) -> String:
	if customer_events.is_empty():
		return "No customer visits recorded yet."
	var lines: Array[String] = []
	for index in range(customer_events.size() - 1, -1, -1):
		var event := customer_events[index]
		if str(event.get("type", "")) == "visitor":
			var faction_text := _faction_text(str(event.get("faction_id", "")))
			var descriptor := _safe_text(event.get("customer_type", "Customer"))
			if not faction_text.is_empty():
				descriptor += " - " + faction_text
			lines.append("[b]%s[/b]  %s\n%s" % [_safe_text(event.get("visitor_name", "Customer")), descriptor, _safe_text(event.get("message", "Visited the shop."))])
		else:
			lines.append("[color=#d7b879]Faction update[/color]\n%s" % _safe_text(event.get("message", "Standing changed.")))
	return "\n\n".join(lines)


func _build_commissions_text(commission_events: Array[Dictionary]) -> String:
	if commission_events.is_empty():
		return "No Adventurer Commissions recorded yet."
	var lines: Array[String] = []
	for index in range(commission_events.size() - 1, -1, -1):
		var event := commission_events[index]
		var status := "Completed" if str(event.get("status", "")) == "completed" else "Offered"
		var line := "[b]%s[/b]  %s\n%s - %s" % [status, _safe_text(event.get("title", "Commission")), _safe_text(event.get("requester_name", "A customer")), _faction_text(str(event.get("faction_id", "")))]
		var area := int(event.get("area", 0))
		if area > 0:
			line += "\nArea %d" % area
		var reward := int(event.get("reward", 0))
		if reward > 0:
			line += "  |  Reward: %dg" % reward
		lines.append(line)
	return "\n\n".join(lines)


func _build_dungeon_text(dungeon_events: Array[Dictionary]) -> String:
	if dungeon_events.is_empty():
		return "No dungeon activity recorded yet."
	var lines: Array[String] = []
	for index in range(dungeon_events.size() - 1, -1, -1):
		var event := dungeon_events[index]
		var subtype := str(event.get("subtype", "activity")).capitalize()
		var line := "[color=#d7b879][b]%s[/b][/color]\n%s" % [subtype, _safe_text(event.get("message", "Dungeon activity recorded."))]
		var amount := int(event.get("amount", 0))
		if amount > 0:
			line += "  |  +%d" % amount
		lines.append(line)
	return "\n\n".join(lines)


func _build_debt_text(debt_events: Array[Dictionary]) -> String:
	if debt_events.is_empty():
		return "No debt activity recorded yet."
	var lines: Array[String] = []
	for index in range(debt_events.size() - 1, -1, -1):
		var event := debt_events[index]
		var line := "[b]%s[/b]" % _safe_text(event.get("message", "Debt activity recorded."))
		var amount := int(event.get("amount", 0))
		var balance := int(event.get("balance", -1))
		if amount > 0:
			line += "\nAmount: %dg" % amount
		if balance >= 0:
			line += "  |  Balance: %dg" % balance
		lines.append(line)
	return "\n\n".join(lines)


func _faction_text(faction_id: String) -> String:
	if faction_id.is_empty():
		return ""
	var faction_manager := get_node_or_null("/root/FactionManager")
	if faction_manager != null:
		return _safe_text(faction_manager.call("get_display_name", faction_id))
	return _safe_text(faction_id)


func _safe_text(value: Variant) -> String:
	var safe := str(value).replace("[", "__shop_log_open_bracket__")
	safe = safe.replace("]", "[rb]")
	return safe.replace("__shop_log_open_bracket__", "[lb]")
