extends CanvasLayer

signal shown
signal hidden

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var button_save: Button = $Control/HBoxContainer/Button_save
@onready var button_load: Button = $Control/HBoxContainer/Button_load
@onready var mymap: map = $Map
@onready var save_menu: SaveMenu = $SaveMenu

var is_paused : bool = false
var pause_thumbnail: Image = null

func _ready() -> void:
	hide_pause_menu()
	button_save.pressed.connect(_on_save_pressed)
	button_load.pressed.connect(_on_load_pressed)
	save_menu.save_requested.connect(_on_save_slot_requested)
	save_menu.load_requested.connect(_on_load_slot_requested)
	save_menu.closed.connect(_on_save_menu_closed)
	pass
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		if save_menu.visible:
			save_menu.close()
			get_viewport().set_input_as_handled()
			return
		var menu_manager := _get_menu_manager()
		if mymap.visible:
			hide_map()
		elif menu_manager != null and bool(menu_manager.call("has_active_menu")) and not bool(menu_manager.call("is_active", self)):
			menu_manager.call("close_active")
		elif is_paused == false:
			show_pause_menu()
		else:
			hide_pause_menu()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("map"):
		if mymap.visible:
			hide_map()
		else:
			show_map()
		get_viewport().set_input_as_handled()
		
func show_pause_menu() -> void:
	if save_menu.visible:
		save_menu.close()
	pause_thumbnail = SaveManager.capture_thumbnail()
	var menu_manager := _get_menu_manager()
	if menu_manager != null:
		menu_manager.call("open", self)
	get_tree().paused = true
	visible = true
	$Control.visible = true
	is_paused = true
	button_save.grab_focus()
	shown.emit()
	button_load.disabled = not SaveManager.has_any_save()
	button_load.visible = SaveManager.has_any_save()

func hide_pause_menu() -> void:
	save_menu.close()
	mymap.close()
	var menu_manager := _get_menu_manager()
	if menu_manager != null:
		menu_manager.call("close", self)
	get_tree().paused = false
	visible = false
	$Control.visible = true
	is_paused = false
	hidden.emit()


func show_map() -> void:
	save_menu.close()
	var menu_manager := _get_menu_manager()
	if menu_manager != null:
		menu_manager.call("open", self)
	get_tree().paused = true
	visible = true
	$Control.visible = false
	is_paused = false
	mymap.open()


func hide_map() -> void:
	mymap.close()
	var menu_manager := _get_menu_manager()
	if menu_manager != null:
		menu_manager.call("close", self)
	get_tree().paused = false
	visible = false
	$Control.visible = true
	is_paused = false
	
func _on_save_pressed() -> void:
	if is_paused == false:
		return
	$Control.visible = false
	save_menu.open_save(pause_thumbnail)

func _on_load_pressed() -> void:
	if is_paused == false:
		return
	$Control.visible = false
	save_menu.open_load()


func _on_save_slot_requested(slot_id: String, thumbnail: Image) -> void:
	if not is_paused:
		return
	var saved: bool = SaveManager.save_to_slot(slot_id, thumbnail)
	save_menu.close()
	if saved:
		hide_pause_menu()


func _on_load_slot_requested(slot_id: String) -> void:
	if not is_paused:
		return
	var loaded: bool = await SaveManager.load_slot(slot_id)
	save_menu.close()
	if loaded:
		hide_pause_menu()
	else:
		$Control.visible = true
		button_load.grab_focus()


func _on_save_menu_closed() -> void:
	if is_paused:
		$Control.visible = true
		button_save.grab_focus()
	

func _on_button_quit_pressed() -> void:
	get_tree().quit()

	

	
func play_audio(audio : AudioStream) -> void:
	audio_stream_player.stream = audio
	audio_stream_player.play()


func _get_menu_manager() -> Node:
	return get_node_or_null("/root/MenuManager")
