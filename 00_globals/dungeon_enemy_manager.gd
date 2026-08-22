extends Node

const ROOM_SAVE_KEY := "enemy_rooms"
const ROOM_STATE_FORMAT := 2
const FLOOR_THREAT_BUDGET := {1: 4, 2: 6, 3: 8, 4: 10, 5: 12}

var room_states: Dictionary = {}
var current_room_path := ""
var current_scene_id := 0
var runtime_serial := 0


func _ready() -> void:
	LevelManager.level_load_started.connect(_capture_current_room)
	LevelManager.level_loaded.connect(_queue_register_current_room)
	SaveManager.game_loaded.connect(_on_game_loaded)
	call_deferred("_queue_register_current_room")


func _on_game_loaded() -> void:
	_load_save_data()
	_queue_register_current_room()


func _load_save_data() -> void:
	room_states = {}
	var saved_states: Variant = SaveManager.current_save.get(ROOM_SAVE_KEY, {})
	if not saved_states is Dictionary:
		return
	for room_path: Variant in saved_states:
		var room_state: Variant = saved_states[room_path]
		if room_state is Dictionary:
			room_states[str(room_path)] = _migrate_room_state(room_state as Dictionary)


func sync_save_data() -> void:
	_capture_current_room()
	SaveManager.current_save[ROOM_SAVE_KEY] = room_states.duplicate(true)


func get_save_data() -> Dictionary:
	sync_save_data()
	return room_states.duplicate(true)


func spawn_enemy(enemy_scene: PackedScene, spawn_position: Vector2, spawn_id := "") -> Enemy:
	if enemy_scene == null:
		return null
	var level_root := get_tree().current_scene as Node2D
	if level_root == null:
		return null
	runtime_serial += 1
	if spawn_id.is_empty():
		spawn_id = "%s::runtime_%d_%d" % [_get_room_path(level_root), Time.get_ticks_msec(), runtime_serial]
	return _spawn_enemy_instance(level_root, _get_room_path(level_root), enemy_scene, spawn_position, spawn_id, "manual", "", 0, 0, null, Vector2(96.0, 64.0))


func reset_current_room_state() -> void:
	if current_room_path.is_empty():
		return
	room_states.erase(current_room_path)
	current_scene_id = 0
	_queue_register_current_room()


func _queue_register_current_room() -> void:
	call_deferred("_register_current_room")


func _register_current_room() -> void:
	await get_tree().physics_frame
	var level_root := get_tree().current_scene as Node2D
	if level_root == null:
		return
	var room_path := _get_room_path(level_root)
	if room_path.is_empty():
		return
	var scene_id := level_root.get_instance_id()
	if scene_id == current_scene_id and room_path == current_room_path:
		return
	current_room_path = room_path
	current_scene_id = scene_id
	var room_state := _get_room_state(room_path, true)
	room_state["visit_count"] = int(room_state.get("visit_count", 0)) + 1
	room_state["last_visit"] = Time.get_unix_time_from_system()
	_register_static_enemies(level_root, room_path, room_state)
	_restore_saved_runtime_enemies(level_root, room_path, room_state)
	_spawn_for_room(level_root, room_path, room_state)
	room_states[room_path] = room_state


func _register_static_enemies(level_root: Node2D, room_path: String, room_state: Dictionary) -> void:
	var registered_ids: Dictionary = {}
	for enemy in _get_room_enemies(level_root):
		_register_enemy(enemy, room_path)
		registered_ids[enemy.persistence_id] = true
		if room_state.get("dead_ids", []).has(enemy.persistence_id):
			enemy.call_deferred("queue_free")
			continue
		var active_states: Variant = room_state.get("active", {})
		if active_states is Dictionary and (active_states as Dictionary).has(enemy.persistence_id):
			var enemy_state: Variant = (active_states as Dictionary).get(enemy.persistence_id, {})
			if enemy_state is Dictionary:
				_restore_enemy_state(enemy, enemy_state as Dictionary)
		if enemy.get_meta("dungeon_enemy_runtime", false):
			enemy.set_meta("dungeon_enemy_registered", true)
	room_state["registered_ids"] = registered_ids


func _restore_saved_runtime_enemies(level_root: Node2D, room_path: String, room_state: Dictionary) -> void:
	var active_states: Variant = room_state.get("active", {})
	if not active_states is Dictionary:
		return
	var registered_ids: Dictionary = room_state.get("registered_ids", {})
	for saved_id: Variant in active_states:
		var enemy_id := str(saved_id)
		if registered_ids.has(enemy_id) or room_state.get("dead_ids", []).has(enemy_id):
			continue
		var saved_state: Variant = (active_states as Dictionary).get(saved_id, {})
		if not saved_state is Dictionary:
			continue
		var state := saved_state as Dictionary
		if bool(state.get("runtime", false)) or str(state.get("kind", "")) == "spawn_point":
			_restore_runtime_enemy(level_root, room_path, enemy_id, state)


func _capture_current_room() -> void:
	var level_root := get_tree().current_scene as Node2D
	if level_root != null:
		_capture_room_state(level_root)


func _capture_room_state(level_root: Node2D) -> void:
	var room_path := _get_room_path(level_root)
	if room_path.is_empty():
		return
	var room_state := _get_room_state(room_path, true)
	var active_states: Dictionary = {}
	for enemy in _get_room_enemies(level_root):
		_register_enemy(enemy, room_path)
		if enemy.is_dead or enemy.hp <= 0 or enemy.is_queued_for_deletion():
			continue
		var enemy_state := enemy.get_persistence_state()
		enemy_state["scene_path"] = enemy.scene_file_path
		enemy_state["runtime"] = bool(enemy.get_meta("dungeon_enemy_runtime", false))
		enemy_state["kind"] = str(enemy.get_meta("enemy_source_kind", "static"))
		enemy_state["spawn_point_id"] = str(enemy.get_meta("enemy_spawn_point_id", ""))
		enemy_state["spawn_cycle"] = int(enemy.get_meta("enemy_spawn_cycle", 0))
		enemy_state["spawn_slot"] = int(enemy.get_meta("enemy_spawn_slot", 0))
		active_states[enemy.persistence_id] = enemy_state
	room_state["active"] = active_states
	room_state.erase("registered_ids")
	room_state["last_visit"] = Time.get_unix_time_from_system()
	room_states[room_path] = room_state


func _register_enemy(enemy: Enemy, room_path: String) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	if enemy.persistence_id.is_empty():
		enemy.persistence_id = "%s::%s" % [room_path, str(enemy.get_path())]
	enemy.persistence_room_key = room_path
	if not enemy.has_meta("dungeon_enemy_persistence_connected"):
		enemy.enemy_destroyed.connect(_on_enemy_destroyed.bind(enemy))
		enemy.set_meta("dungeon_enemy_persistence_connected", true)


func _on_enemy_destroyed(_hurt_box: HurtBox, enemy: Enemy) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var room_path := enemy.persistence_room_key
	if room_path.is_empty():
		return
	var room_state := _get_room_state(room_path, true)
	var spawn_point_id := str(enemy.get_meta("enemy_spawn_point_id", ""))
	if not spawn_point_id.is_empty():
		_handle_spawn_point_enemy_destroyed(enemy, room_state, spawn_point_id)
		return
	var dead_ids: Array = room_state.get("dead_ids", [])
	if not dead_ids.has(enemy.persistence_id):
		dead_ids.append(enemy.persistence_id)
	room_state["dead_ids"] = dead_ids
	var active_states: Variant = room_state.get("active", {})
	if active_states is Dictionary:
		(active_states as Dictionary).erase(enemy.persistence_id)
	room_state["active"] = active_states
	room_states[room_path] = room_state


func _handle_spawn_point_enemy_destroyed(enemy: Enemy, room_state: Dictionary, spawn_point_id: String) -> void:
	var active_states: Variant = room_state.get("active", {})
	if active_states is Dictionary:
		(active_states as Dictionary).erase(enemy.persistence_id)
	room_state["active"] = active_states
	var point_states: Dictionary = room_state.get("spawn_points", {})
	var point_state: Dictionary = point_states.get(spawn_point_id, {})
	point_state["initialized"] = true
	if _has_active_spawn_point_enemy(spawn_point_id):
		point_states[spawn_point_id] = point_state
		room_state["spawn_points"] = point_states
		room_states[enemy.persistence_room_key] = room_state
		return
	var spawn_point := _find_spawn_point(spawn_point_id)
	if spawn_point == null or spawn_point.respawn_policy == EnemySpawnPoint.RespawnPolicy.NEVER:
		point_state["permanently_cleared"] = true
		point_state["next_respawn_visit"] = -1
	else:
		point_state["permanently_cleared"] = false
		point_state["next_respawn_visit"] = int(room_state.get("visit_count", 0)) + spawn_point.respawn_after_visits
	point_states[spawn_point_id] = point_state
	room_state["spawn_points"] = point_states
	room_states[enemy.persistence_room_key] = room_state


func _restore_runtime_enemy(level_root: Node2D, room_path: String, enemy_id: String, state: Dictionary) -> void:
	var scene_path := str(state.get("scene_path", ""))
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return
	var enemy_scene := load(scene_path) as PackedScene
	if enemy_scene == null:
		return
	var spawn_point_id := str(state.get("spawn_point_id", ""))
	var spawn_point := _find_spawn_point_in_room(level_root, spawn_point_id)
	var route := _find_route(level_root, str(state.get("patrol_route_id", "")))
	var enemy := _spawn_enemy_instance(level_root, room_path, enemy_scene, Vector2(float(state.get("position_x", 0.0)), float(state.get("position_y", 0.0))), enemy_id, str(state.get("kind", "manual")), spawn_point_id, int(state.get("spawn_cycle", 0)), int(state.get("spawn_slot", 0)), route, spawn_point.patrol_radius if spawn_point != null else Vector2(96.0, 64.0))
	if enemy != null:
		_restore_enemy_state(enemy, state)


func _spawn_for_room(level_root: Node2D, room_path: String, room_state: Dictionary) -> void:
	var floor_number := _get_floor_number(room_path)
	var remaining_budget := _get_room_budget(level_root, floor_number)
	var points: Array[EnemySpawnPoint] = []
	for node in get_tree().get_nodes_in_group("enemy_spawn_points"):
		var point := node as EnemySpawnPoint
		if point != null and level_root.is_ancestor_of(point) and point.is_available_on_floor(floor_number):
			points.append(point)
	points.sort_custom(func(first: EnemySpawnPoint, second: EnemySpawnPoint): return first.priority < second.priority)
	var point_states: Dictionary = room_state.get("spawn_points", {})
	for point in points:
		if point.spawn_point_id.is_empty():
			push_warning("EnemySpawnPoint has no spawn_point_id: %s" % point.get_path())
			continue
		if _has_active_spawn_point_enemy(point.spawn_point_id):
			continue
		var point_state: Dictionary = point_states.get(point.spawn_point_id, {})
		if bool(point_state.get("permanently_cleared", false)):
			continue
		var initialized := bool(point_state.get("initialized", false))
		if initialized and int(room_state.get("visit_count", 0)) < int(point_state.get("next_respawn_visit", 0)):
			continue
		var random := RandomNumberGenerator.new()
		if not initialized:
			point_state["selection_seed"] = randi()
			point_state["cycle"] = 0
		else:
			point_state["cycle"] = int(point_state.get("cycle", 0)) + 1
		random.seed = int(point_state.get("selection_seed", randi())) + int(point_state.get("cycle", 0)) * 9973
		var choices: Array[Dictionary] = []
		var total_cost := 0
		var positions := point.get_spawn_positions()
		for slot in mini(point.population, positions.size()):
			var choice := point.choose_enemy(floor_number, random)
			if choice.get("scene", null) == null:
				continue
			choices.append({"choice": choice, "position": positions[slot], "slot": slot})
			total_cost += int(choice.get("threat_cost", 1))
		if choices.is_empty() or (not point.ignore_room_budget and total_cost > remaining_budget):
			continue
		var route := point.get_patrol_route()
		var spawned_count := 0
		for spawn_data in choices:
			var choice: Dictionary = spawn_data["choice"]
			var position := _resolve_spawn_position(level_root, spawn_data["position"])
			if position == Vector2.INF:
				continue
			var spawn_id := "%s::spawn::%s::%d::%d" % [room_path, point.spawn_point_id, int(point_state.get("cycle", 0)), int(spawn_data["slot"])]
			if _spawn_enemy_instance(level_root, room_path, choice["scene"], position, spawn_id, "spawn_point", point.spawn_point_id, int(point_state.get("cycle", 0)), int(spawn_data["slot"]), route, point.patrol_radius) != null:
				spawned_count += 1
		if spawned_count == 0:
			continue
		if not point.ignore_room_budget:
			remaining_budget -= total_cost
		point_state["initialized"] = true
		point_state["next_respawn_visit"] = -1
		point_state["permanently_cleared"] = false
		point_states[point.spawn_point_id] = point_state
	room_state["spawn_points"] = point_states


func _spawn_enemy_instance(level_root: Node2D, room_path: String, enemy_scene: PackedScene, spawn_position: Vector2, spawn_id: String, source_kind: String, spawn_point_id: String, spawn_cycle: int, spawn_slot: int, route: PatrolRoute, patrol_radius: Vector2) -> Enemy:
	if enemy_scene == null:
		return null
	var enemy := enemy_scene.instantiate() as Enemy
	if enemy == null:
		return null
	enemy.persistence_id = spawn_id
	enemy.global_position = spawn_position
	enemy.configure_patrol(spawn_position, patrol_radius)
	if route != null:
		enemy.configure_patrol_route(route, route.route_id)
	enemy.set_meta("dungeon_enemy_runtime", true)
	enemy.set_meta("enemy_source_kind", source_kind)
	enemy.set_meta("enemy_spawn_point_id", spawn_point_id)
	enemy.set_meta("enemy_spawn_cycle", spawn_cycle)
	enemy.set_meta("enemy_spawn_slot", spawn_slot)
	level_root.add_child(enemy)
	_register_enemy(enemy, room_path)
	return enemy


func _restore_enemy_state(enemy: Enemy, state: Dictionary) -> void:
	enemy.restore_persistence_state(state)


func _has_active_spawn_point_enemy(spawn_point_id: String) -> bool:
	if spawn_point_id.is_empty():
		return false
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null and is_instance_valid(enemy) and str(enemy.get_meta("enemy_spawn_point_id", "")) == spawn_point_id and not enemy.is_dead:
			return true
	return false


func _find_spawn_point(spawn_point_id: String) -> EnemySpawnPoint:
	return _find_spawn_point_in_room(get_tree().current_scene as Node2D, spawn_point_id)


func _find_spawn_point_in_room(level_root: Node2D, spawn_point_id: String) -> EnemySpawnPoint:
	if level_root == null or spawn_point_id.is_empty():
		return null
	for node in get_tree().get_nodes_in_group("enemy_spawn_points"):
		var point := node as EnemySpawnPoint
		if point != null and level_root.is_ancestor_of(point) and point.spawn_point_id == spawn_point_id:
			return point
	return null


func _find_route(level_root: Node2D, route_id: String) -> PatrolRoute:
	if level_root == null or route_id.is_empty():
		return null
	for node in get_tree().get_nodes_in_group("enemy_patrol_routes"):
		var route := node as PatrolRoute
		if route != null and level_root.is_ancestor_of(route) and route.route_id == route_id:
			return route
	return null


func _resolve_spawn_position(level_root: Node2D, desired_position: Vector2) -> Vector2:
	var position := desired_position
	if not DungeonPathfinder.is_walkable(position):
		position = DungeonPathfinder.find_nearest_walkable(position)
	if position == Vector2.INF:
		return Vector2.INF
	if _is_position_free(level_root, position):
		return position
	var nearest := DungeonPathfinder.find_nearest_walkable(position + Vector2(20, 0))
	if nearest != Vector2.INF and _is_position_free(level_root, nearest):
		return nearest
	return Vector2.INF


func _is_position_free(level_root: Node2D, position: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = position
	query.collision_mask = 272
	query.collide_with_areas = false
	if PlayerManager.player != null:
		query.exclude.append(PlayerManager.player.get_rid())
	return level_root.get_world_2d().direct_space_state.intersect_point(query).is_empty()


func _get_room_budget(level_root: Node2D, floor_number: int) -> int:
	for node in get_tree().get_nodes_in_group("room_encounter_settings"):
		var settings := node as RoomEncounterSettings
		if settings != null and level_root.is_ancestor_of(settings):
			return settings.get_threat_budget(floor_number)
	return int(FLOOR_THREAT_BUDGET.get(floor_number, 0))


func _get_room_enemies(level_root: Node2D) -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or not is_instance_valid(enemy) or not level_root.is_ancestor_of(enemy):
			continue
		enemies.append(enemy)
	return enemies


func _get_room_state(room_path: String, create_if_missing: bool) -> Dictionary:
	var saved_state: Variant = room_states.get(room_path, {})
	var room_state: Dictionary = _migrate_room_state(saved_state as Dictionary) if saved_state is Dictionary else {}
	if create_if_missing:
		room_states[room_path] = room_state
	return room_state


func _migrate_room_state(saved_state: Dictionary) -> Dictionary:
	var room_state := saved_state.duplicate(true)
	room_state["format"] = ROOM_STATE_FORMAT
	if not room_state.has("dead_ids"):
		room_state["dead_ids"] = []
	if not room_state.has("active"):
		room_state["active"] = {}
	if not room_state.has("spawn_points"):
		room_state["spawn_points"] = {}
	if not room_state.has("visit_count"):
		room_state["visit_count"] = 0
	return room_state


func _get_floor_number(scene_path: String) -> int:
	var regex := RegEx.new()
	regex.compile("Area_(\\d+)")
	var result := regex.search(scene_path)
	if result == null:
		return 1
	return int(result.get_string(1))


func _get_room_path(level_root: Node2D) -> String:
	return level_root.scene_file_path
