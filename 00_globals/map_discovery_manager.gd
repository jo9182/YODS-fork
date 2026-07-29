extends Node

signal room_discovered(scene_path: String)

const AREA_PREFIX := "res://Levels/Area_"
var discovered_rooms: Dictionary = {}
var floor_layouts: Dictionary = {}


func _ready() -> void:
	SaveManager.game_loaded.connect(_load_from_save)
	_load_from_save()


func discover_current_room() -> bool:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false
	return discover_room(current_scene.scene_file_path)


func discover_room(scene_path: String) -> bool:
	if get_floor_number(scene_path) == 0 or discovered_rooms.has(scene_path):
		return false
	discovered_rooms[scene_path] = true
	_store_in_save()
	room_discovered.emit(scene_path)
	SaveManager.save_game()
	return true


func get_floor_number(scene_path: String) -> int:
	if not scene_path.begins_with(AREA_PREFIX):
		return 0
	var floor_start := AREA_PREFIX.length()
	var floor_end := scene_path.find("/", floor_start)
	if floor_end == -1:
		return 0
	return int(scene_path.substr(floor_start, floor_end - floor_start))


func get_discovered_rooms(floor_number: int) -> Array[String]:
	var rooms: Array[String] = []
	for scene_path in discovered_rooms:
		if get_floor_number(scene_path) == floor_number:
			rooms.append(scene_path)
	return rooms


func get_floor_layout(floor_number: int) -> Dictionary:
	if floor_layouts.has(floor_number):
		return floor_layouts[floor_number]
	var room_paths := _get_room_paths(floor_number)
	var edges: Dictionary = {}
	var bounds: Dictionary = {}
	for scene_path in room_paths:
		var room_data: Dictionary = _get_room_data(scene_path)
		edges[scene_path] = room_data.get("edges", [])
		bounds[scene_path] = room_data.get("bounds", Rect2(-Vector2(8.0, 6.0), Vector2(16.0, 12.0)))
	var positions := _build_positions(room_paths, edges)
	var layout := {"positions": positions, "edges": edges, "bounds": bounds}
	floor_layouts[floor_number] = layout
	return layout


func _load_from_save() -> void:
	discovered_rooms.clear()
	var saved_rooms = SaveManager.current_save.get("map_discovery", [])
	if saved_rooms is Array:
		for scene_path in saved_rooms:
			if scene_path is String and get_floor_number(scene_path) > 0:
				discovered_rooms[scene_path] = true


func _store_in_save() -> void:
	SaveManager.current_save["map_discovery"] = discovered_rooms.keys()


func _get_room_paths(floor_number: int) -> Array[String]:
	var directory_path := "%s%d" % [AREA_PREFIX, floor_number]
	var room_paths: Array[String] = []
	for file_name in DirAccess.get_files_at(directory_path):
		if file_name.get_extension() == "tscn":
			room_paths.append("%s/%s" % [directory_path, file_name])
	room_paths.sort()
	return room_paths


func _get_room_data(scene_path: String) -> Dictionary:
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		return {"edges": [], "bounds": Rect2(-Vector2(8.0, 6.0), Vector2(16.0, 12.0))}
	var room := packed_scene.instantiate()
	var room_edges: Array[Dictionary] = []
	for node in room.find_children("*", "", true, false):
		if node is level_transition:
			var target_path := ResourceUID.ensure_path(node.level)
			if get_floor_number(target_path) > 0:
				room_edges.append({
					"name": node.name,
					"target": target_path,
					"source_position": node.position,
					"target_transition": node.target_transition_area,
				})
	var tilemap := _find_tilemap(room)
	var room_bounds := _get_room_bounds(tilemap)
	room.free()
	return {"edges": room_edges, "bounds": room_bounds}


func _build_positions(room_paths: Array[String], edges: Dictionary) -> Dictionary:
	var positions: Dictionary = {}
	if room_paths.is_empty():
		return positions
	var pending: Array[String] = [room_paths[0]]
	positions[room_paths[0]] = Vector2.ZERO
	while not pending.is_empty():
		var scene_path: String = pending.pop_front()
		var position: Vector2 = positions[scene_path]
		for edge in edges.get(scene_path, []):
			var target_path: String = edge.get("target", "")
			if not room_paths.has(target_path) or positions.has(target_path):
				continue
			var source_position: Vector2 = edge.get("source_position", Vector2.ZERO)
			var target_position := _get_transition_position(edges.get(target_path, []), edge.get("target_transition", ""))
			positions[target_path] = position + source_position - target_position
			pending.append(target_path)
	var loose_index := 0
	for scene_path in room_paths:
		if positions.has(scene_path):
			continue
		positions[scene_path] = Vector2(640.0 + loose_index % 4 * 256.0, floori(float(loose_index) / 4.0) * 192.0)
		loose_index += 1
	return positions


func _get_transition_position(transitions: Array, transition_name: String) -> Vector2:
	for transition in transitions:
		if transition.get("name", "") == transition_name:
			return transition.get("source_position", Vector2.ZERO)
	return Vector2.ZERO


func _find_tilemap(node: Node) -> TileMapLayer:
	if node is TileMapLayer:
		return node
	for child in node.get_children():
		var tilemap := _find_tilemap(child)
		if tilemap != null:
			return tilemap
	return null


func _get_room_bounds(tilemap: TileMapLayer) -> Rect2:
	if tilemap == null or tilemap.tile_set == null:
		return Rect2(-Vector2(8.0, 6.0), Vector2(16.0, 12.0))
	var used_rect := tilemap.get_used_rect()
	var tile_size := Vector2(tilemap.tile_set.tile_size)
	return Rect2(tilemap.position + Vector2(used_rect.position) * tile_size, Vector2(used_rect.size) * tile_size)
