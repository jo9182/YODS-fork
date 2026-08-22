class_name AdventurerSpawnPoint extends Marker2D

@export var spawn_point_id := ""
@export_range(1, 6, 1) var party_size := 1
@export var min_floor := 1
@export var max_floor := 4
@export var patrol_route_path: NodePath
@export var enabled := true
@export_range(0, 100, 1) var priority := 0


func _ready() -> void:
	add_to_group("adventurer_spawn_points")


func is_available_on_floor(floor_number: int) -> bool:
	return enabled and floor_number >= min_floor and floor_number <= max_floor


func get_patrol_route() -> PatrolRoute:
	if patrol_route_path.is_empty():
		return null
	return get_node_or_null(patrol_route_path) as PatrolRoute
