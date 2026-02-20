class_name ShopLogMenu extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var entries_label: RichTextLabel = $Panel/VBoxContainer/EntriesLabel
@onready var total_label: Label = $Panel/VBoxContainer/TotalLabel
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton


func _ready() -> void:
	panel.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_button.pressed.connect(_close)
	ShopLog.log_updated.connect(_refresh)

	# DEBUG: confirm node wiring
	print("[ShopLogMenu] entries_label = ", entries_label)
	print("[ShopLogMenu] total_label = ", total_label)
	print("[ShopLogMenu] ShopLog entries at start = ", ShopLog.entries.size())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shop_log"):
		if panel.visible:
			_close()
		else:
			_open()


func _open() -> void:
	_refresh()
	panel.visible = true
	get_tree().paused = true


func _close() -> void:
	panel.visible = false
	get_tree().paused = false


func _refresh() -> void:
	var entries = ShopLog.entries
	print("[ShopLogMenu] _refresh called, entries count = ", entries.size())

	if entries.is_empty():
		entries_label.text = "No sales yet."
	else:
		var lines: Array[String] = []
		for i in range(entries.size() - 1, -1, -1):
			var e = entries[i]
			lines.append("%s — %s — %dg" % [e["item_name"], e["buyer"], e["price"]])
		entries_label.text = "\n".join(lines)
		print("[ShopLogMenu] text set to: ", entries_label.text)

	total_label.text = "Total earned: %dg" % ShopLog.total_earned()
