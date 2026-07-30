class_name DungeonMapCanvas extends Control

const FALLBACK_ROOM_BOUNDS := Rect2(-Vector2(8.0, 6.0), Vector2(16.0, 12.0))

var positions: Dictionary = {}
var edges: Dictionary = {}
var bounds: Dictionary = {}
var discovered: Dictionary = {}
var room_markers: Dictionary = {}
var current_room := ""
var current_player_position := Vector2.INF
var map_origin := Vector2.ZERO
var map_scale := 1.0


func configure(layout: Dictionary, discovered_rooms: Array, current_scene_path: String, marker_data: Dictionary = {}, player_position: Vector2 = Vector2.INF) -> void:
	positions = layout.get("positions", {})
	edges = layout.get("edges", {})
	bounds = layout.get("bounds", {})
	room_markers = marker_data
	discovered.clear()
	for scene_path in discovered_rooms:
		discovered[scene_path] = true
	current_room = current_scene_path
	current_player_position = player_position
	queue_redraw()


func _draw() -> void:
	_draw_grid()
	var known_rooms: Array[String] = []
	for scene_path in discovered:
		if positions.has(scene_path):
			known_rooms.append(scene_path)
	if known_rooms.is_empty():
		_draw_empty_message()
		return
	_prepare_transform(known_rooms)
	_draw_connections(known_rooms)
	for scene_path in known_rooms:
		_draw_room(scene_path)
	_draw_exits(known_rooms)
	_draw_markers(known_rooms)
	_draw_player_marker()


func _draw_grid() -> void:
	var grid_color := Color(0.16, 0.22, 0.28, 0.35)
	for x in range(0, int(size.x) + 1, 12):
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, 1.0)
	for y in range(0, int(size.y) + 1, 12):
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)


func _draw_empty_message() -> void:
	var font := get_theme_default_font()
	draw_string(font, Vector2(16, size.y * 0.5), "Open the map inside a dungeon room to chart it.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.72, 0.78, 0.82))


func _prepare_transform(known_rooms: Array[String]) -> void:
	var first_rect := _get_world_rect(known_rooms[0])
	var minimum := first_rect.position
	var maximum := first_rect.end
	for scene_path in known_rooms:
		var room_rect := _get_world_rect(scene_path)
		minimum.x = minf(minimum.x, room_rect.position.x)
		minimum.y = minf(minimum.y, room_rect.position.y)
		maximum.x = maxf(maximum.x, room_rect.end.x)
		maximum.y = maxf(maximum.y, room_rect.end.y)
	var span := maximum - minimum
	var available_size := size - Vector2(36.0, 36.0)
	map_scale = minf(1.0, minf(available_size.x / maxf(span.x, 1.0), available_size.y / maxf(span.y, 1.0)))
	map_origin = (size - span * map_scale) * 0.5 - minimum * map_scale


func _draw_connections(known_rooms: Array[String]) -> void:
	for scene_path in known_rooms:
		for edge in edges.get(scene_path, []):
			var target_path: String = edge.get("target", "")
			if discovered.has(target_path) and positions.has(target_path):
				var source_door: Vector2 = _get_door_position(scene_path, edge)
				var target_door: Vector2 = _get_target_door_position(target_path, edge.get("target_transition", ""))
				_draw_hallway(_to_canvas_position(source_door), _to_canvas_position(target_door))


func _draw_hallway(from: Vector2, to: Vector2) -> void:
	if from.distance_to(to) < 0.5:
		return
	draw_line(from, to, Color(0.06, 0.12, 0.15, 0.9), maxf(5.0, 8.0 * map_scale))
	draw_line(from, to, Color(0.35, 0.78, 0.71, 0.85), maxf(2.0, 4.0 * map_scale))


func _draw_exits(known_rooms: Array[String]) -> void:
	for scene_path in known_rooms:
		for edge in edges.get(scene_path, []):
			var target_path: String = edge.get("target", "")
			var exit_position := _to_canvas_position(_get_door_position(scene_path, edge))
			var exit_color := Color(0.92, 0.96, 0.98) if discovered.has(target_path) else Color(0.57, 0.66, 0.71)
			draw_circle(exit_position, 3.2, Color(0.04, 0.08, 0.1, 0.95))
			draw_circle(exit_position, 1.75, exit_color)


func _draw_room(scene_path: String) -> void:
	var room_rect := _to_canvas_rect(_get_world_rect(scene_path))
	var fill_color := Color(0.20, 0.66, 0.62) if scene_path != current_room else Color(0.95, 0.76, 0.29)
	var outline_color := Color(0.62, 0.93, 0.87) if scene_path != current_room else Color(1.0, 0.93, 0.62)
	draw_rect(room_rect, fill_color)
	draw_rect(room_rect, outline_color, false, maxf(1.0, 2.0 * map_scale))


func _draw_markers(known_rooms: Array[String]) -> void:
	for scene_path in known_rooms:
		for marker in room_markers.get(scene_path, []):
			var marker_position := Vector2(float(marker.get("x", 0.0)), float(marker.get("y", 0.0)))
			var world_position: Vector2 = positions.get(scene_path, Vector2.ZERO) + marker_position
			_draw_marker(_to_canvas_position(world_position), marker.get("kind", ""))


func _draw_marker(position: Vector2, kind: String) -> void:
	match kind:
		"chest":
			draw_rect(Rect2(position - Vector2(3.5, 2.5), Vector2(7.0, 5.0)), Color(0.1, 0.06, 0.03, 0.9))
			draw_rect(Rect2(position - Vector2(2.25, 1.5), Vector2(4.5, 3.0)), Color(0.63, 0.34, 0.13))
		"opened_chest":
			draw_rect(Rect2(position - Vector2(3.5, 2.5), Vector2(7.0, 5.0)), Color(0.1, 0.06, 0.03, 0.9))
			draw_rect(Rect2(position - Vector2(2.25, 1.5), Vector2(4.5, 3.0)), Color(0.32, 0.2, 0.13))
		"torch":
			draw_circle(position, 3.5, Color(0.16, 0.07, 0.02, 0.9))
			draw_circle(position, 2.0, Color(1.0, 0.56, 0.16))
		"explorer":
			draw_circle(position, 3.6, Color(0.05, 0.08, 0.16, 0.9))
			draw_circle(position, 2.1, Color(0.35, 0.65, 1.0))


func _draw_player_marker() -> void:
	if not discovered.has(current_room):
		return
	var marker_position := current_player_position
	if not marker_position.is_finite():
		marker_position = bounds.get(current_room, FALLBACK_ROOM_BOUNDS).get_center()
	var world_position: Vector2 = positions.get(current_room, Vector2.ZERO) + marker_position
	var canvas_position := _to_canvas_position(world_position)
	var room_rect := _to_canvas_rect(_get_world_rect(current_room)).grow(-3.0)
	canvas_position = canvas_position.clamp(room_rect.position, room_rect.end)
	draw_circle(canvas_position, 4.4, Color(0.08, 0.06, 0.02, 0.95))
	draw_circle(canvas_position, 2.6, Color(1.0, 0.98, 0.82))


func _get_door_position(scene_path: String, edge: Dictionary) -> Vector2:
	var room_position: Vector2 = positions.get(scene_path, Vector2.ZERO)
	var door_position: Vector2 = edge.get("source_position", Vector2.ZERO)
	return room_position + door_position


func _get_target_door_position(target_path: String, transition_name: String) -> Vector2:
	for edge in edges.get(target_path, []):
		if edge.get("name", "") == transition_name:
			return _get_door_position(target_path, edge)
	return _get_world_rect(target_path).get_center()


func _to_canvas_position(world_position: Vector2) -> Vector2:
	return map_origin + world_position * map_scale


func _get_world_rect(scene_path: String) -> Rect2:
	var room_position: Vector2 = positions.get(scene_path, Vector2.ZERO)
	var room_bounds: Rect2 = bounds.get(scene_path, FALLBACK_ROOM_BOUNDS)
	return Rect2(room_position + room_bounds.position, room_bounds.size)


func _to_canvas_rect(world_rect: Rect2) -> Rect2:
	return Rect2(map_origin + world_rect.position * map_scale, world_rect.size * map_scale)
