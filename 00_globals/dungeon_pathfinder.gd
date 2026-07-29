extends Node

const WALL_COLLISION_MASK := 16
const OPEN_CELL_SEARCH_RADIUS := 3

var _tilemap: TileMapLayer
var _grid: AStarGrid2D
var _scene_id := 0


func _ready() -> void:
	LevelManager.level_loaded.connect(_queue_rebuild)
	call_deferred("_rebuild_for_active_scene")


func _queue_rebuild() -> void:
	call_deferred("_rebuild_for_active_scene")


func _rebuild_for_active_scene() -> void:
	await get_tree().physics_frame
	var level_root := get_tree().current_scene as Node2D
	if level_root == null:
		_clear()
		return
	var scene_id := level_root.get_instance_id()
	if scene_id == _scene_id and _grid != null:
		return
	_tilemap = _find_tilemap(level_root)
	if _tilemap == null or _tilemap.tile_set == null:
		_clear()
		return
	_scene_id = scene_id
	_grid = AStarGrid2D.new()
	_grid.region = _tilemap.get_used_rect()
	_grid.cell_size = Vector2(_tilemap.tile_set.tile_size)
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_grid.update()
	for cell_x in range(_grid.region.position.x, _grid.region.end.x):
		for cell_y in range(_grid.region.position.y, _grid.region.end.y):
			var cell := Vector2i(cell_x, cell_y)
			if _tilemap.get_cell_source_id(cell) == -1 or _is_wall(level_root, _cell_to_global(cell)):
				_grid.set_point_solid(cell)


func get_point_path(from_global: Vector2, to_global: Vector2) -> PackedVector2Array:
	if _grid == null or _tilemap == null:
		return PackedVector2Array()
	var from_cell := _nearest_open_cell(_global_to_cell(from_global))
	var to_cell := _nearest_open_cell(_global_to_cell(to_global))
	if from_cell == Vector2i.MAX or to_cell == Vector2i.MAX:
		return PackedVector2Array()
	var cell_path := _grid.get_id_path(from_cell, to_cell)
	if cell_path.is_empty():
		return PackedVector2Array()
	var path := PackedVector2Array()
	for cell in cell_path:
		path.append(_cell_to_global(cell))
	return path


func is_walkable(world_position: Vector2) -> bool:
	if _grid == null or _tilemap == null:
		return false
	var cell := _global_to_cell(world_position)
	return _grid.is_in_boundsv(cell) and not _grid.is_point_solid(cell)


func get_wander_point(anchor: Vector2, max_offset: Vector2) -> Vector2:
	if _grid == null:
		return anchor
	for attempt in range(12):
		var candidate := anchor + Vector2(randf_range(-max_offset.x, max_offset.x), randf_range(-max_offset.y, max_offset.y))
		if is_walkable(candidate):
			return candidate
	return _cell_to_global(_nearest_open_cell(_global_to_cell(anchor)))


func _find_tilemap(node: Node) -> TileMapLayer:
	if node is TileMapLayer:
		return node
	for child in node.get_children():
		var tilemap := _find_tilemap(child)
		if tilemap != null:
			return tilemap
	return null


func _is_wall(level_root: Node2D, world_position: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_position
	query.collision_mask = WALL_COLLISION_MASK
	query.collide_with_areas = false
	query.collide_with_bodies = true
	for explorer in get_tree().get_nodes_in_group("dungeon_explorers"):
		if explorer is CollisionObject2D:
			query.exclude.append(explorer.get_rid())
	var player := PlayerManager.player
	if player != null:
		query.exclude.append(player.get_rid())
	return not level_root.get_world_2d().direct_space_state.intersect_point(query).is_empty()


func _nearest_open_cell(cell: Vector2i) -> Vector2i:
	var clamped_cell := Vector2i(
		clampi(cell.x, _grid.region.position.x, _grid.region.end.x - 1),
		clampi(cell.y, _grid.region.position.y, _grid.region.end.y - 1)
	)
	for radius in range(OPEN_CELL_SEARCH_RADIUS + 1):
		for offset_x in range(-radius, radius + 1):
			for offset_y in range(-radius, radius + 1):
				if radius > 0 and abs(offset_x) != radius and abs(offset_y) != radius:
					continue
				var candidate := clamped_cell + Vector2i(offset_x, offset_y)
				if _grid.is_in_boundsv(candidate) and not _grid.is_point_solid(candidate):
					return candidate
	return Vector2i.MAX


func _global_to_cell(world_position: Vector2) -> Vector2i:
	return _tilemap.local_to_map(_tilemap.to_local(world_position))


func _cell_to_global(cell: Vector2i) -> Vector2:
	return _tilemap.to_global(_tilemap.map_to_local(cell))


func _clear() -> void:
	_tilemap = null
	_grid = null
	_scene_id = 0
