extends CanvasLayer

signal shown
signal hidden

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var button_save: Button = $Control/HBoxContainer/Button_save
@onready var button_load: Button = $Control/HBoxContainer/Button_load
@onready var mymap: map = $Map

var is_paused : bool = false

func _ready() -> void:
	hide_pause_menu()
	button_save.pressed.connect(_on_save_pressed)
	button_load.pressed.connect(_on_load_pressed)
	pass
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
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
	var menu_manager := _get_menu_manager()
	if menu_manager != null:
		menu_manager.call("open", self)
	get_tree().paused = true
	visible = true
	$Control.visible = true
	is_paused = true
	button_save.grab_focus()
	shown.emit()
	if SaveManager.get_save_file() == null:
		button_load.disabled = true
		button_load.visible = false

func hide_pause_menu() -> void:
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
	SaveManager.save_game()
	hide_pause_menu()
	if button_load.disabled == true:
		button_load.disabled = false
		button_load.visible = true
	pass

func _on_load_pressed() -> void:
	if is_paused == false:
		return
	SaveManager.load_game()
	await LevelManager.level_load_started
	hide_pause_menu()
	pass
	

func _on_button_quit_pressed() -> void:
	get_tree().quit()

	

	
func play_audio(audio : AudioStream) -> void:
	audio_stream_player.stream = audio
	audio_stream_player.play()


func _get_menu_manager() -> Node:
	return get_node_or_null("/root/MenuManager")
