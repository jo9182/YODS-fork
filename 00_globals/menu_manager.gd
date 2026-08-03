extends Node

signal active_menu_changed(menu: Node)

var active_menu: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if not (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		return
	if active_menu == null or not is_instance_valid(active_menu):
		active_menu = null
		return
	close_active()
	get_viewport().set_input_as_handled()


func open(menu: Node) -> void:
	if menu == null or not is_instance_valid(menu):
		return
	if active_menu == menu:
		return
	var previous_menu := active_menu
	active_menu = menu
	if previous_menu != null and is_instance_valid(previous_menu):
		_close_node(previous_menu)
	active_menu_changed.emit(active_menu)


func close(menu: Node) -> void:
	if active_menu != menu:
		return
	active_menu = null
	active_menu_changed.emit(null)


func close_active() -> void:
	var menu := active_menu
	if menu == null or not is_instance_valid(menu):
		active_menu = null
		return
	active_menu = null
	active_menu_changed.emit(null)
	_close_node(menu)


func is_active(menu: Node) -> bool:
	return active_menu == menu and is_instance_valid(active_menu)


func has_active_menu() -> bool:
	return active_menu != null and is_instance_valid(active_menu)


func _close_node(menu: Node) -> void:
	if menu.has_method("close"):
		menu.call("close")
	elif menu.has_method("hide_pause_menu"):
		menu.call("hide_pause_menu")
	else:
		menu.hide()
