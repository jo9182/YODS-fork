class_name SaveMenu
extends Control

signal save_requested(slot_id, thumbnail)
signal load_requested(slot_id)
signal closed

enum MenuMode {
	SAVE,
	LOAD,
}

@onready var title_label: Label = $Panel/VBoxContainer/Title
@onready var subtitle_label: Label = $Panel/VBoxContainer/Subtitle
@onready var slot_list: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/SlotList
@onready var cancel_button: Button = $Panel/VBoxContainer/Cancel

var mode: MenuMode = MenuMode.SAVE
var thumbnail: Image = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	cancel_button.pressed.connect(close)
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()


func open_save(save_thumbnail: Image = null) -> void:
	_open(MenuMode.SAVE, save_thumbnail)


func open_load() -> void:
	_open(MenuMode.LOAD, null)


func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


func _open(next_mode: MenuMode, save_thumbnail: Image) -> void:
	mode = next_mode
	thumbnail = save_thumbnail
	visible = true
	_build_slot_list()
	title_label.text = "SAVE GAME" if mode == MenuMode.SAVE else "LOAD GAME"
	subtitle_label.text = "Choose a save slot" if mode == MenuMode.SAVE else "Choose a save slot or autosave"
	cancel_button.grab_focus()


func _build_slot_list() -> void:
	for child: Node in slot_list.get_children():
		child.queue_free()
	for slot_id: String in SaveManager.get_manual_slot_ids():
		_add_slot_row(slot_id, true)
	if mode == MenuMode.LOAD:
		_add_slot_row(SaveManager.AUTOSAVE_SLOT_ID, false)


func _add_slot_row(slot_id: String, can_save: bool) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 58)
	row.add_theme_constant_override("separation", 8)
	slot_list.add_child(row)

	var preview: TextureRect = TextureRect.new()
	preview.custom_minimum_size = Vector2(104, 58)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(preview)

	var info: Dictionary = SaveManager.get_slot_info(slot_id)
	var image: Image = _load_thumbnail(slot_id)
	if image != null:
		preview.texture = ImageTexture.create_from_image(image)
	else:
		var preview_label: Label = Label.new()
		preview_label.text = "NO PREVIEW"
		preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		preview.add_child(preview_label)

	var details: VBoxContainer = VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(details)
	var slot_label: Label = Label.new()
	slot_label.text = "AUTOSAVE" if slot_id == SaveManager.AUTOSAVE_SLOT_ID else "SLOT " + slot_id.trim_prefix("slot_")
	details.add_child(slot_label)
	var detail_label: Label = Label.new()
	detail_label.text = _format_details(info)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details.add_child(detail_label)

	var action_button: Button = Button.new()
	action_button.custom_minimum_size = Vector2(70, 0)
	action_button.text = "SAVE" if mode == MenuMode.SAVE else "LOAD"
	action_button.disabled = mode == MenuMode.LOAD and not bool(info.get("exists", false))
	if mode == MenuMode.SAVE and not can_save:
		action_button.disabled = true
	action_button.pressed.connect(_on_slot_pressed.bind(slot_id))
	row.add_child(action_button)


func _on_slot_pressed(slot_id: String) -> void:
	if mode == MenuMode.SAVE:
		save_requested.emit(slot_id, thumbnail)
	else:
		load_requested.emit(slot_id)


func _format_details(info: Dictionary) -> String:
	if not bool(info.get("exists", false)):
		return "Empty slot"
	var scene_name: String = str(info.get("scene_name", "Unknown room"))
	var saved_at: String = str(info.get("saved_at", ""))
	if saved_at.is_empty():
		return scene_name
	return scene_name + "\n" + saved_at.replace("T", " ")


func _load_thumbnail(slot_id: String) -> Image:
	if not SaveManager.has_thumbnail(slot_id):
		return null
	var image: Image = Image.new()
	if image.load(SaveManager.get_thumbnail_path(slot_id)) != OK:
		return null
	return image
