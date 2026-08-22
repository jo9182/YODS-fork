extends Node

const SAVE_PATH: String = "user://"
const SAVE_VERSION: int = 3
const MANUAL_SLOT_IDS: Array[String] = ["slot_1", "slot_2", "slot_3"]
const AUTOSAVE_SLOT_ID: String = "autosave"
const LEGACY_SAVE_FILE: String = "save.sav"
const THUMBNAIL_DIRECTORY: String = "user://save_thumbnails/"
const THUMBNAIL_WIDTH: int = 160

signal game_loaded
signal game_saved
signal save_changed

var current_save: Dictionary = _default_save()
var active_slot: String = "slot_1"
var is_test_session: bool = false
var is_loading: bool = false


func _ready() -> void:
	call_deferred("_ensure_faction_manager")


func set_test_session(active: bool) -> void:
	is_test_session = active


func get_manual_slot_ids() -> Array[String]:
	return MANUAL_SLOT_IDS.duplicate()


func get_all_slot_ids() -> Array[String]:
	var slots: Array[String] = MANUAL_SLOT_IDS.duplicate()
	slots.append(AUTOSAVE_SLOT_ID)
	return slots


func is_manual_slot(slot_id: String) -> bool:
	return MANUAL_SLOT_IDS.has(slot_id)


func is_valid_slot(slot_id: String) -> bool:
	return is_manual_slot(slot_id) or slot_id == AUTOSAVE_SLOT_ID


func has_slot(slot_id: String) -> bool:
	if not is_valid_slot(slot_id):
		return false
	return not _get_existing_save_path(slot_id).is_empty()


func has_any_save() -> bool:
	for slot_id: String in get_all_slot_ids():
		if has_slot(slot_id):
			return true
	return false


func has_any_manual_save() -> bool:
	for slot_id: String in MANUAL_SLOT_IDS:
		if has_slot(slot_id):
			return true
	return false


func get_preferred_load_slot() -> String:
	if is_manual_slot(active_slot) and has_slot(active_slot):
		return active_slot
	var newest_slot: String = ""
	var newest_timestamp: int = -1
	for slot_id: String in get_all_slot_ids():
		var info: Dictionary = get_slot_info(slot_id)
		if not bool(info.get("exists", false)):
			continue
		var timestamp: int = int(info.get("timestamp", 0))
		if timestamp >= newest_timestamp:
			newest_timestamp = timestamp
			newest_slot = slot_id
	return newest_slot


func save_game() -> void:
	var slot_id: String = active_slot if is_manual_slot(active_slot) else MANUAL_SLOT_IDS[0]
	save_to_slot(slot_id)


func autosave_game() -> void:
	if is_test_session or is_loading:
		return
	if _get_current_level_path().is_empty():
		return
	save_to_slot(AUTOSAVE_SLOT_ID)


func save_to_slot(slot_id: String, thumbnail: Image = null) -> bool:
	if not is_valid_slot(slot_id):
		return false
	if is_test_session:
		game_saved.emit()
		return true

	_sync_runtime_state()
	if current_save.scene_path.is_empty():
		return false
	if thumbnail == null:
		thumbnail = capture_thumbnail()

	var state: Dictionary = current_save.duplicate(true)
	state["save_version"] = SAVE_VERSION
	var metadata: Dictionary = _build_metadata(slot_id, state)
	var payload: Dictionary = {
		"format_version": SAVE_VERSION,
		"metadata": metadata,
		"state": state,
	}
	var file_path: String = _get_save_path(slot_id)
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save slot for writing: %s" % file_path)
		return false
	file.store_line(JSON.stringify(payload))
	file.close()
	if thumbnail != null:
		_ensure_thumbnail_directory()
		thumbnail.save_png(get_thumbnail_path(slot_id))
	if is_manual_slot(slot_id):
		active_slot = slot_id
	game_saved.emit()
	save_changed.emit()
	return true


func capture_thumbnail() -> Image:
	var viewport: Viewport = get_viewport()
	if viewport == null or viewport.get_texture() == null:
		return null
	var image: Image = viewport.get_texture().get_image()
	if image == null or image.is_empty():
		return null
	var thumbnail: Image = image.duplicate()
	var target_height: int = maxi(1, roundi(float(thumbnail.get_height()) * float(THUMBNAIL_WIDTH) / float(thumbnail.get_width())))
	thumbnail.resize(THUMBNAIL_WIDTH, target_height, Image.INTERPOLATE_NEAREST)
	return thumbnail


func get_thumbnail_path(slot_id: String) -> String:
	if not is_valid_slot(slot_id):
		return ""
	return THUMBNAIL_DIRECTORY + slot_id + ".png"


func has_thumbnail(slot_id: String) -> bool:
	var thumbnail_path: String = get_thumbnail_path(slot_id)
	return not thumbnail_path.is_empty() and FileAccess.file_exists(thumbnail_path)


func get_slot_info(slot_id: String) -> Dictionary:
	var info: Dictionary = {
		"slot_id": slot_id,
		"exists": false,
		"timestamp": 0,
		"saved_at": "",
		"scene_path": "",
		"scene_name": "",
		"thumbnail_path": get_thumbnail_path(slot_id),
	}
	if not is_valid_slot(slot_id):
		return info
	var payload: Dictionary = _read_slot_payload(slot_id)
	if payload.is_empty():
		return info
	var state: Dictionary = payload.get("state", {})
	var metadata: Dictionary = payload.get("metadata", {})
	info["exists"] = true
	info["timestamp"] = int(metadata.get("timestamp", 0))
	info["saved_at"] = str(metadata.get("saved_at", ""))
	info["scene_path"] = str(metadata.get("scene_path", state.get("scene_path", "")))
	info["scene_name"] = str(metadata.get("scene_name", _scene_name(info["scene_path"])))
	return info


func get_save_file(slot_id: String = "") -> FileAccess:
	var requested_slot: String = slot_id
	if requested_slot.is_empty():
		requested_slot = active_slot if is_manual_slot(active_slot) else MANUAL_SLOT_IDS[0]
	var file_path: String = _get_existing_save_path(requested_slot)
	if file_path.is_empty():
		return null
	return FileAccess.open(file_path, FileAccess.READ)


func load_game() -> void:
	var slot_id: String = get_preferred_load_slot()
	if slot_id.is_empty():
		return
	load_slot(slot_id)


func load_autosave() -> void:
	load_slot(AUTOSAVE_SLOT_ID)


func load_slot(slot_id: String) -> bool:
	if not is_valid_slot(slot_id):
		return false
	var payload: Dictionary = _read_slot_payload(slot_id)
	if payload.is_empty():
		return false
	var state_variant: Variant = payload.get("state", {})
	if not state_variant is Dictionary:
		return false
	var state: Dictionary = _merge_with_defaults(state_variant as Dictionary)
	var scene_path: String = str(state.get("scene_path", ""))
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_error("Save slot has no valid scene path: %s" % slot_id)
		return false

	current_save = state
	if is_manual_slot(slot_id):
		active_slot = slot_id
	is_loading = true
	LevelManager.load_new_level(scene_path, "", Vector2.ZERO)
	await LevelManager.level_load_started

	var player_data_variant: Variant = current_save.get("player", {})
	var player_data: Dictionary = player_data_variant as Dictionary if player_data_variant is Dictionary else {}
	PlayerManager.set_player_position(Vector2(float(player_data.get("pos_x", 0.0)), float(player_data.get("pos_y", 0.0))))
	PlayerManager.set_health(int(player_data.get("hp", 1)), int(player_data.get("max_hp", 1)))
	PlayerManager.INVENTORY_DATA.parseSave(current_save.get("items", []))
	PlayerStats.gold = int(current_save.get("gold", 0))
	ReputationManager.load_save_data(current_save.get("reputation", {}))
	var faction_manager: Node = get_node_or_null("/root/FactionManager")
	if faction_manager != null:
		faction_manager.call("load_save_data", current_save.get("factions", {}))
	ShopLog.load_save_data(current_save.get("shop_log", []))

	var all_skills: Array[SkillData] = _find_all_skills()
	var purchased_skills_variant: Variant = current_save.get("purchased_skills", [])
	var purchased_skills: Array = purchased_skills_variant as Array if purchased_skills_variant is Array else []
	SkillTreeManager.load_save_data(purchased_skills, all_skills)

	await LevelManager.level_loaded
	is_loading = false
	game_loaded.emit()
	print("load game: %s" % slot_id)
	return true


func update_player_data() -> void:
	if PlayerManager.player == null:
		return
	var player: Player = PlayerManager.player
	current_save.player.hp = player.hp
	current_save.player.max_hp = player.max_hp
	current_save.player.pos_x = player.global_position.x
	current_save.player.pos_y = player.global_position.y


func update_scene_path() -> void:
	var path: String = _get_current_level_path()
	if not path.is_empty():
		current_save.scene_path = path


func update_item_data() -> void:
	current_save.items = PlayerManager.INVENTORY_DATA.getSaveData()


func add_persistent_value(value: String) -> void:
	if check_persistent_value(value) == false:
		current_save.persistience.append(value)


func check_persistent_value(value: String) -> bool:
	var persistent_values: Array = current_save.persistience as Array
	return persistent_values.has(value)


func _sync_runtime_state() -> void:
	update_player_data()
	update_scene_path()
	update_item_data()
	var enemy_manager: Node = get_node_or_null("/root/DungeonEnemyManager")
	if enemy_manager != null:
		enemy_manager.call("sync_save_data")
	current_save.gold = PlayerStats.gold
	current_save.purchased_skills = SkillTreeManager.get_save_data()
	current_save.reputation = ReputationManager.get_save_data()
	var faction_manager: Node = get_node_or_null("/root/FactionManager")
	if faction_manager != null:
		current_save.factions = faction_manager.call("get_save_data")
	current_save.shop_log = ShopLog.get_save_data()


func _default_save() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"scene_path": "",
		"player": {
			"hp": 1,
			"max_hp": 1,
			"pos_x": 0,
			"pos_y": 0,
		},
		"gold": 0,
		"purchased_skills": [],
		"items": [],
		"persistience": [],
		"quest": [],
		"chests": [],
		"torches": {},
		"dungeon_renown": {},
		"enemy_rooms": {},
		"reputation": {},
		"factions": {},
		"map_discovery": [],
		"map_markers": {},
		"commissions": {},
		"tax_debt": {},
		"shop_upgrades": [],
		"shop_log": [],
	}


func _merge_with_defaults(saved_state: Dictionary) -> Dictionary:
	var merged: Dictionary = _default_save()
	for key: Variant in saved_state:
		merged[key] = saved_state[key]
	return merged


func _build_metadata(slot_id: String, state: Dictionary) -> Dictionary:
	var scene_path: String = str(state.get("scene_path", ""))
	return {
		"slot_id": slot_id,
		"saved_at": Time.get_datetime_string_from_system(),
		"timestamp": int(Time.get_unix_time_from_system()),
		"scene_path": scene_path,
		"scene_name": _scene_name(scene_path),
	}


func _scene_name(scene_path: String) -> String:
	if scene_path.is_empty():
		return "Unknown room"
	return scene_path.get_file().get_basename().replace("_", " ").capitalize()


func _get_current_level_path() -> String:
	for child: Node in get_tree().root.get_children():
		if child is level:
			return child.scene_file_path
	return ""


func _get_save_path(slot_id: String) -> String:
	return SAVE_PATH + "save_" + slot_id + ".sav"


func _get_existing_save_path(slot_id: String) -> String:
	if not is_valid_slot(slot_id):
		return ""
	var new_path: String = _get_save_path(slot_id)
	if FileAccess.file_exists(new_path):
		return new_path
	if slot_id == MANUAL_SLOT_IDS[0] and FileAccess.file_exists(SAVE_PATH + LEGACY_SAVE_FILE):
		return SAVE_PATH + LEGACY_SAVE_FILE
	return ""


func _read_slot_payload(slot_id: String) -> Dictionary:
	var file_path: String = _get_existing_save_path(slot_id)
	if file_path.is_empty():
		return {}
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}
	var line: String = file.get_line()
	file.close()
	if line.is_empty():
		return {}
	var json: JSON = JSON.new()
	if json.parse(line) != OK:
		return {}
	var parsed: Variant = json.data
	if not parsed is Dictionary:
		return {}
	var data: Dictionary = parsed as Dictionary
	if data.has("state") and data.get("state") is Dictionary:
		return {
			"state": data.get("state") as Dictionary,
			"metadata": data.get("metadata", {}) as Dictionary,
		}
	return {
		"state": data,
		"metadata": {},
	}


func _ensure_thumbnail_directory() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(THUMBNAIL_DIRECTORY))


func _find_all_skills() -> Array[SkillData]:
	for node: Node in get_tree().get_nodes_in_group("altar"):
		if node.has_method("get") and node.get("skill_tree") != null:
			return node.skill_tree.skills
	return []


func _ensure_faction_manager() -> void:
	if get_node_or_null("/root/FactionManager") != null:
		return
	var faction_script: GDScript = load("res://shop/faction_manager.gd") as GDScript
	if faction_script == null:
		return
	var faction_manager: Node = faction_script.new() as Node
	faction_manager.name = "FactionManager"
	get_tree().root.add_child(faction_manager)
