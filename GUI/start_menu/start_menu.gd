extends Node2D

const START_LEVEL : String = "res://Levels/Area_1/the_shop.tscn"
const OPTIONS_MENU : PackedScene = preload("res://GUI/start_menu/options_menu.tscn")


@export var music : AudioStream
@export var button_focus_audio : AudioStream
@export var button_press_audio : AudioStream

@onready var button_new: Button = $CanvasLayer/Control/ButtonNew
@onready var button_continue: Button = $CanvasLayer/Control/ButtonContinue
@onready var button_options: Button = $CanvasLayer/Control/ButtonOptions
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var save_menu: SaveMenu = $CanvasLayer/SaveMenu



func _ready() -> void:
	OptionsMenu.load_and_apply_settings()

	get_tree().paused = true
	PlayerManager.player.visible = false
	
	PlayerHud.visible = false
	PauseMenu.process_mode = Node.PROCESS_MODE_DISABLED
	
	if not SaveManager.has_any_save():
		button_continue.disabled = true
		button_continue.visible = false
	
	setup_title_screen()
	save_menu.load_requested.connect(_on_load_slot_requested)
	save_menu.closed.connect(_on_save_menu_closed)
	
	LevelManager.level_load_started.connect( exit_title_screen )
	
	
	pass


func setup_title_screen() -> void:
	button_new.pressed.connect( start_game )
	button_continue.pressed.connect( load_game )
	button_options.pressed.connect( open_options )
	button_new.grab_focus()
	
	button_new.focus_entered.connect( play_audio.bind( button_focus_audio ) )
	button_continue.focus_entered.connect( play_audio.bind( button_focus_audio ) )
	button_options.focus_entered.connect( play_audio.bind( button_focus_audio ) )
	pass


func open_options() -> void:
	play_audio( button_press_audio )
	var options_instance := OPTIONS_MENU.instantiate()
	add_child(options_instance)
	var menu_manager := get_node_or_null("/root/MenuManager")
	if menu_manager != null:
		menu_manager.call("open", options_instance)
	options_instance.options_closed.connect(_on_options_closed)
	_set_menu_buttons_disabled(true)


func _on_options_closed() -> void:
	_set_menu_buttons_disabled(false)
	button_options.grab_focus()


func _set_menu_buttons_disabled(disabled: bool) -> void:
	button_new.disabled = disabled
	button_continue.disabled = disabled
	button_options.disabled = disabled


func start_game() -> void:
	play_audio( button_press_audio )
	LevelManager.load_new_level( START_LEVEL, "", Vector2.ZERO )
	pass

func load_game() -> void:
	play_audio( button_press_audio )
	_set_menu_buttons_disabled(true)
	$CanvasLayer/Control.visible = false
	save_menu.open_load()


func _on_load_slot_requested(slot_id: String) -> void:
	var loaded: bool = await SaveManager.load_slot(slot_id)
	if not loaded and is_inside_tree():
		save_menu.close()


func _on_save_menu_closed() -> void:
	if not is_inside_tree():
		return
	$CanvasLayer/Control.visible = true
	_set_menu_buttons_disabled(false)
	button_continue.grab_focus()

func exit_title_screen() -> void:
	PlayerManager.player.visible = true
	PlayerHud.visible = true
	PauseMenu.process_mode = Node.PROCESS_MODE_ALWAYS
	self.queue_free()
	pass

func play_audio( _a : AudioStream ) -> void:
	audio_stream_player.stream = _a
	audio_stream_player.play()
