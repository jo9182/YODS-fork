class_name OptionsMenu
extends CanvasLayer

signal options_closed

const SETTINGS_PATH := "user://settings.cfg"

enum WindowPreset { S_1920x1080 = 0, S_1600x900 = 1, S_1280x720 = 2, S_960x540 = 3 }

const RESOLUTIONS := {
	WindowPreset.S_1920x1080: Vector2i(1920, 1080),
	WindowPreset.S_1600x900: Vector2i(1600, 900),
	WindowPreset.S_1280x720: Vector2i(1280, 720),
	WindowPreset.S_960x540: Vector2i(960, 540),
}

@onready var resolution_option: OptionButton = $Panel/VBoxContainer/ResolutionContainer/OptionButton
@onready var fullscreen_check: CheckButton = $Panel/VBoxContainer/FullscreenContainer/CheckButton
@onready var volume_slider: HSlider = $Panel/VBoxContainer/VolumeContainer/HSlider
@onready var back_button: Button = $Panel/VBoxContainer/BackButton


func _ready() -> void:
	_populate_resolutions()
	_load_settings_into_ui()

	back_button.pressed.connect(_on_back_pressed)
	resolution_option.item_selected.connect(_on_resolution_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	volume_slider.value_changed.connect(_on_volume_changed)


func _populate_resolutions() -> void:
	resolution_option.clear()
	for preset in WindowPreset.values():
		var size: Vector2i = RESOLUTIONS[preset]
		resolution_option.add_item("%dx%d" % [size.x, size.y])


func _load_settings_into_ui() -> void:
	load_and_apply_settings()

	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		fullscreen_check.button_pressed = config.get_value("display", "fullscreen", false)
		var saved_size: Vector2i = config.get_value("display", "window_size", Vector2i(1920, 1080))
		for preset in WindowPreset.values():
			if RESOLUTIONS[preset] == saved_size:
				resolution_option.select(preset)
				break
		volume_slider.value = config.get_value("audio", "master_volume", 1.0)
	else:
		fullscreen_check.button_pressed = false
		resolution_option.select(0)
		volume_slider.value = 1.0


func _save_settings() -> void:
	var config := ConfigFile.new()
	var preset: int = resolution_option.get_selected_id()
	if RESOLUTIONS.has(preset):
		config.set_value("display", "window_size", RESOLUTIONS[preset])
	config.set_value("display", "fullscreen", fullscreen_check.button_pressed)
	config.set_value("audio", "master_volume", volume_slider.value)
	config.save(SETTINGS_PATH)


static func load_and_apply_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return

	var fullscreen: bool = config.get_value("display", "fullscreen", false)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var window_size: Vector2i = config.get_value("display", "window_size", Vector2i(1920, 1080))
		DisplayServer.window_set_size(window_size)

	var volume: float = config.get_value("audio", "master_volume", 1.0)
	var master_bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(volume))


func _on_resolution_changed(_index: int) -> void:
	var preset: int = resolution_option.get_selected_id()
	if not RESOLUTIONS.has(preset):
		return
	var size: Vector2i = RESOLUTIONS[preset]
	if not fullscreen_check.button_pressed:
		DisplayServer.window_set_size(size)
	_save_settings()


func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var preset: int = resolution_option.get_selected_id()
		if RESOLUTIONS.has(preset):
			DisplayServer.window_set_size(RESOLUTIONS[preset])
	_save_settings()


func _on_volume_changed(value: float) -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))
	_save_settings()


func _on_back_pressed() -> void:
	options_closed.emit()
	queue_free()
