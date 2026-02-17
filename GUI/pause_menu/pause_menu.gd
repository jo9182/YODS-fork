extends CanvasLayer

signal shown
signal hidden

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var button_save: Button = $Control/HBoxContainer/Button_save
@onready var button_load: Button = $Control/HBoxContainer/Button_load

var is_paused : bool = false

func _ready() -> void:
	hide_pause_menu()
	button_save.pressed.connect(_on_save_pressed)
	button_load.pressed.connect(_on_load_pressed)
	pass
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if is_paused == false:
			show_pause_menu()
			InventoryMenu.process_mode = Node.PROCESS_MODE_DISABLED
		else:
			hide_pause_menu()
			InventoryMenu.process_mode = Node.PROCESS_MODE_ALWAYS
		get_viewport().set_input_as_handled()
		
func show_pause_menu() -> void:
	get_tree().paused = true
	visible = true
	is_paused = true
	button_save.grab_focus()
	shown.emit()
	if SaveManager.get_save_file() == null:
		button_load.disabled = true
		button_load.visible = false

func hide_pause_menu() -> void:
	get_tree().paused = false
	visible = false
	is_paused = false
	hidden.emit()
	
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
