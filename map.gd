class_name map extends CanvasLayer

@onready var title_label: Label = $Control/TitleLabel
@onready var subtitle_label: Label = $Control/SubtitleLabel
@onready var room_map: DungeonMapCanvas = $Control/RoomMap


func _ready() -> void:
	visible = false


func open() -> void:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return
	var scene_path := current_scene.scene_file_path
	var floor_number := MapDiscoveryManager.get_floor_number(scene_path)
	visible = true
	if floor_number == 0:
		title_label.text = "Dungeon Map"
		subtitle_label.text = "No dungeon chart is available here."
		room_map.configure({}, [], "")
		return
	MapDiscoveryManager.discover_current_room()
	var layout := MapDiscoveryManager.get_floor_layout(floor_number)
	var discovered_rooms := MapDiscoveryManager.get_discovered_rooms(floor_number)
	title_label.text = "Dungeon Map  ·  Floor %d" % floor_number
	subtitle_label.text = "%d rooms charted  ·  Gold marker is your position" % discovered_rooms.size()
	room_map.configure(layout, discovered_rooms, scene_path)


func close() -> void:
	visible = false
