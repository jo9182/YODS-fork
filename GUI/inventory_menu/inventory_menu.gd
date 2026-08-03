extends CanvasLayer

signal shown
signal hidden

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var item_description: Label = $"Control/Item Description"

var is_paused : bool = false

func _ready() -> void:
	hide_inventory_menu()
	pass
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if is_paused == false:
			show_inventory_menu()
		else:
			hide_inventory_menu()
		get_viewport().set_input_as_handled()


func close() -> void:
	hide_inventory_menu()
func show_inventory_menu() -> void:
	var menu_manager := get_node_or_null("/root/MenuManager")
	if menu_manager != null:
		menu_manager.call("open", self)
	get_tree().paused = true
	visible = true
	is_paused = true
	shown.emit()

func hide_inventory_menu() -> void:
	var menu_manager := get_node_or_null("/root/MenuManager")
	if menu_manager != null:
		menu_manager.call("close", self)
	get_tree().paused = false
	visible = false
	is_paused = false
	hidden.emit()
	
func _on_save_pressed() -> void:
	if is_paused == false:
		return
	SaveManager.save_game()
	hide_inventory_menu()
	pass

func _on_load_pressed() -> void:
	if is_paused == false:
		return
	SaveManager.load_game()
	await LevelManager.level_load_started
	hide_inventory_menu()
	pass
	
func update_item_description(new_text : String) -> void:
	item_description.text = new_text
	
func play_audio(audio : AudioStream) -> void:
	audio_stream_player.stream = audio
	audio_stream_player.play()
