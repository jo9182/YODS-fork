extends Node

const EXPLORER_SCENE_PATH := "res://NPC's/dungeon_explorer.tscn"
const EXCLUDED_SCENE_TOKENS := ["arena", "boss", "exit", "settlement", "shop", "town", "altar"]
const FLOOR_SPAWN_LIMITS := {1: 3, 2: 2, 3: 1, 4: 1, 5: 0}
const SPAWN_OFFSETS := [
	Vector2(72, 0), Vector2(-72, 0), Vector2(0, 72), Vector2(0, -72),
	Vector2(96, 48), Vector2(-96, 48), Vector2(96, -48), Vector2(-96, -48),
]
const PARTY_OFFSETS := [
	Vector2(24, 0), Vector2(-24, 0), Vector2(0, 24), Vector2(0, -24),
	Vector2(24, 24), Vector2(-24, 24), Vector2(24, -24), Vector2(-24, -24),
]
const PARTY_NAMES := ["Dawn", "Iron", "Moss", "Ember", "Cinder", "Moon"]

var populated_scene_id := 0
var party_serial := 0


func _ready() -> void:
	LevelManager.level_loaded.connect(_populate_explorers)
	call_deferred("_populate_explorers")


func _populate_explorers() -> void:
	await get_tree().physics_frame
	var level_root := get_tree().current_scene as Node2D
	if level_root == null or not _is_explorer_scene(level_root.scene_file_path):
		return
	var scene_id := level_root.get_instance_id()
	if populated_scene_id == scene_id:
		return
	var player := PlayerManager.player
	if player == null:
		call_deferred("_populate_explorers")
		return
	var renown := get_node_or_null("/root/DungeonRenown")
	if renown == null:
		return
	var explorer_scene := load(EXPLORER_SCENE_PATH) as PackedScene
	if explorer_scene == null:
		return
	populated_scene_id = scene_id
	var floor_number := _get_floor_number(level_root.scene_file_path)
	var spawn_budget := mini(int(renown.call("get_explorer_count")), _get_spawn_limit(floor_number))
	var authored_points := _get_authored_spawn_points(level_root, floor_number)
	if not authored_points.is_empty():
		_populate_authored_explorers(level_root, explorer_scene, floor_number, spawn_budget, authored_points)
		return
	var reserved_positions: Array[Vector2] = []
	while spawn_budget > 0:
		var party_size := _get_party_size(spawn_budget, floor_number)
		var leader_position := _find_spawn_position(level_root, player.global_position, reserved_positions)
		if leader_position == Vector2.INF:
			break
		party_serial += 1
		var party_name: String = PARTY_NAMES[party_serial % PARTY_NAMES.size()]
		var leader := _spawn_explorer(explorer_scene, level_root, leader_position, floor_number)
		leader.configure_party(leader, 0, party_name)
		reserved_positions.append(leader_position)
		var members_spawned := 1
		for party_slot in range(1, party_size):
			var member_position := _find_party_member_position(level_root, leader_position, reserved_positions)
			if member_position == Vector2.INF:
				break
			var member := _spawn_explorer(explorer_scene, level_root, member_position, floor_number)
			member.configure_party(leader, party_slot, party_name)
			reserved_positions.append(member_position)
			members_spawned += 1
		spawn_budget -= members_spawned


func _populate_authored_explorers(level_root: Node2D, explorer_scene: PackedScene, floor_number: int, spawn_budget: int, authored_points: Array[AdventurerSpawnPoint]) -> void:
	var reserved_positions: Array[Vector2] = []
	authored_points.sort_custom(func(first: AdventurerSpawnPoint, second: AdventurerSpawnPoint): return first.priority < second.priority)
	for point in authored_points:
		if spawn_budget <= 0:
			break
		var leader_position := point.global_position
		if not DungeonPathfinder.is_walkable(leader_position) or not _is_position_free(level_root, leader_position):
			leader_position = DungeonPathfinder.find_nearest_walkable(leader_position)
		if leader_position == Vector2.INF or _is_position_reserved(leader_position, reserved_positions):
			continue
		var party_size := mini(point.party_size, spawn_budget)
		party_serial += 1
		var party_name: String = PARTY_NAMES[party_serial % PARTY_NAMES.size()]
		var leader := _spawn_explorer(explorer_scene, level_root, leader_position, floor_number)
		leader.configure_party(leader, 0, party_name)
		leader.configure_patrol_route(point.get_patrol_route())
		reserved_positions.append(leader_position)
		var members_spawned := 1
		for party_slot in range(1, party_size):
			var member_position := _find_party_member_position(level_root, leader_position, reserved_positions)
			if member_position == Vector2.INF:
				break
			var member := _spawn_explorer(explorer_scene, level_root, member_position, floor_number)
			member.configure_party(leader, party_slot, party_name)
			reserved_positions.append(member_position)
			members_spawned += 1
		spawn_budget -= members_spawned


func _get_authored_spawn_points(level_root: Node2D, floor_number: int) -> Array[AdventurerSpawnPoint]:
	var points: Array[AdventurerSpawnPoint] = []
	for node in get_tree().get_nodes_in_group("adventurer_spawn_points"):
		var point := node as AdventurerSpawnPoint
		if point != null and level_root.is_ancestor_of(point) and point.is_available_on_floor(floor_number):
			points.append(point)
	return points


func _is_explorer_scene(scene_path: String) -> bool:
	if not scene_path.begins_with("res://Levels/Area_"):
		return false
	var lowercase_path := scene_path.to_lower()
	for token in EXCLUDED_SCENE_TOKENS:
		if lowercase_path.contains(token):
			return false
	return true


func _get_floor_number(scene_path: String) -> int:
	var regex := RegEx.new()
	regex.compile("Area_(\\d+)")
	var result := regex.search(scene_path)
	if result == null:
		return 1
	return int(result.get_string(1))


func _get_spawn_limit(floor_number: int) -> int:
	return int(FLOOR_SPAWN_LIMITS.get(floor_number, 0))


func _get_party_size(remaining_budget: int, floor_number: int) -> int:
	if remaining_budget < 2 or floor_number >= 3:
		return 1
	if floor_number == 1 and remaining_budget >= 3 and randf() < 0.5:
		return 3
	return 2


func _spawn_explorer(explorer_scene: PackedScene, level_root: Node2D, spawn_position: Vector2, floor_number: int) -> DungeonExplorer:
	var explorer := explorer_scene.instantiate() as DungeonExplorer
	level_root.add_child(explorer)
	explorer.setup(spawn_position, floor_number)
	return explorer


func _find_spawn_position(level_root: Node2D, origin: Vector2, reserved_positions: Array[Vector2]) -> Vector2:
	for spawn_offset in SPAWN_OFFSETS:
		var candidate: Vector2 = origin + spawn_offset
		if _is_position_reserved(candidate, reserved_positions):
			continue
		if not DungeonPathfinder.is_walkable(candidate):
			continue
		if _is_position_free(level_root, candidate):
			return candidate
	return Vector2.INF


func _find_party_member_position(level_root: Node2D, leader_position: Vector2, reserved_positions: Array[Vector2]) -> Vector2:
	for party_offset in PARTY_OFFSETS:
		var candidate: Vector2 = leader_position + party_offset
		if _is_position_reserved(candidate, reserved_positions):
			continue
		if not DungeonPathfinder.is_walkable(candidate):
			continue
		if _is_position_free(level_root, candidate):
			return candidate
	return _find_spawn_position(level_root, leader_position, reserved_positions)


func _is_position_reserved(candidate: Vector2, reserved_positions: Array[Vector2]) -> bool:
	for reserved_position in reserved_positions:
		if candidate.distance_to(reserved_position) < 24.0:
			return true
	return false


func _is_position_free(level_root: Node2D, candidate: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = candidate
	query.collision_mask = 272
	query.collide_with_areas = false
	if PlayerManager.player != null:
		query.exclude = [PlayerManager.player.get_rid()]
	return level_root.get_world_2d().direct_space_state.intersect_point(query).is_empty()
