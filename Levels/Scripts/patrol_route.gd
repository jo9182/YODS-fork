@tool
class_name PatrolRoute extends Node2D

enum TraversalMode { LOOP, PING_PONG, ONCE }

@export var route_id := ""
@export var traversal_mode := TraversalMode.LOOP
@export_range(0.0, 10.0, 0.05) var default_wait_seconds := 0.75
@export var draw_route := true


func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("enemy_patrol_routes")
	queue_redraw()


func _draw() -> void:
	if not draw_route:
		return
	var points := get_waypoints()
	if points.size() < 2:
		return
	for index in points.size():
		var current := to_local(points[index].global_position)
		draw_circle(current, 4.0, Color(0.95, 0.74, 0.26, 0.9))
		if index + 1 < points.size():
			draw_line(current, to_local(points[index + 1].global_position), Color(0.95, 0.74, 0.26, 0.55), 2.0)
	if traversal_mode == TraversalMode.LOOP:
		draw_line(to_local(points[-1].global_position), to_local(points[0].global_position), Color(0.95, 0.74, 0.26, 0.35), 1.0)


func get_waypoints() -> Array[PatrolWaypoint]:
	var points: Array[PatrolWaypoint] = []
	for child in get_children():
		var waypoint := child as PatrolWaypoint
		if waypoint != null:
			points.append(waypoint)
	return points


func get_waypoint_position(index: int) -> Vector2:
	var points := get_waypoints()
	if points.is_empty():
		return global_position
	var clamped_index := clampi(index, 0, points.size() - 1)
	return points[clamped_index].global_position


func get_waypoint_wait(index: int) -> float:
	var points := get_waypoints()
	if points.is_empty():
		return default_wait_seconds
	var clamped_index := clampi(index, 0, points.size() - 1)
	return maxf(points[clamped_index].wait_seconds, 0.0)


func get_next_index(index: int, direction: int) -> Dictionary:
	var points := get_waypoints()
	if points.is_empty():
		return {"index": 0, "direction": 1, "finished": true}
	var current := clampi(index, 0, points.size() - 1)
	var step := 1 if direction >= 0 else -1
	match traversal_mode:
		TraversalMode.LOOP:
			return {"index": posmod(current + step, points.size()), "direction": step, "finished": false}
		TraversalMode.PING_PONG:
			var next := current + step
			var next_direction := step
			if next >= points.size():
				next_direction = -1
				next = maxi(points.size() - 2, 0)
			elif next < 0:
				next_direction = 1
				next = mini(1, points.size() - 1)
			return {"index": next, "direction": next_direction, "finished": false}
		TraversalMode.ONCE:
			var next_once := current + step
			if next_once < 0 or next_once >= points.size():
				return {"index": current, "direction": step, "finished": true}
			return {"index": next_once, "direction": step, "finished": false}
	return {"index": current, "direction": step, "finished": true}

