class_name EnemySpawnPoint extends Marker2D

enum RespawnPolicy { NEVER, AFTER_ROOM_VISITS }

@export var spawn_point_id := ""
@export var encounter_table: EnemyEncounterTable
@export var enemy_scenes: Array[PackedScene] = []
@export_range(1, 12, 1) var population := 1
@export var min_floor := 1
@export var max_floor := 5
@export var patrol_route_path: NodePath
@export var patrol_radius := Vector2(96.0, 64.0)
@export var respawn_policy := RespawnPolicy.AFTER_ROOM_VISITS
@export_range(1, 20, 1) var respawn_after_visits := 4
@export_range(0, 100, 1) var priority := 0
@export var ignore_room_budget := false
@export var enabled := true


func _ready() -> void:
	add_to_group("enemy_spawn_points")


func is_available_on_floor(floor_number: int) -> bool:
	return enabled and floor_number >= min_floor and floor_number <= max_floor


func get_spawn_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for child in get_children():
		var marker := child as Marker2D
		if marker != null:
			positions.append(marker.global_position)
	if positions.is_empty():
		positions.append(global_position)
	return positions


func get_patrol_route() -> PatrolRoute:
	if patrol_route_path.is_empty():
		return null
	return get_node_or_null(patrol_route_path) as PatrolRoute


func choose_enemy(floor_number: int, random: RandomNumberGenerator) -> Dictionary:
	if encounter_table != null:
		var entry := encounter_table.choose_entry(floor_number, random)
		if entry != null:
			return {"scene": entry.enemy_scene, "threat_cost": entry.threat_cost}
	if enemy_scenes.is_empty():
		return {"scene": null, "threat_cost": 0}
	var scene := enemy_scenes[random.randi_range(0, enemy_scenes.size() - 1)]
	return {"scene": scene, "threat_cost": 1}

