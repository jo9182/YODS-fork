extends Node

const TORCH_SCENE_PATH := "res://Props/torch/torch.tscn"

var restored_scene_id := 0


func _ready() -> void:
	LevelManager.level_loaded.connect(restore_current_scene)
	call_deferred("restore_current_scene")


func place_torch(level_root: Node2D, position: Vector2) -> bool:
	if level_root.scene_file_path.is_empty():
		return false
	var scene_state := _get_scene_state(level_root.scene_file_path, true)
	var placement_id := int(scene_state.get("next_id", 0))
	scene_state["next_id"] = placement_id + 1
	var placed = scene_state.get("placed", [])
	placed.append({"id": placement_id, "x": position.x, "y": position.y})
	scene_state["placed"] = placed
	_store_scene_state(level_root.scene_file_path, scene_state)
	_spawn_placed_torch(level_root, position, placement_id)
	return true


func record_torch_broken(torch: Node) -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null or scene_root.scene_file_path.is_empty():
		return
	var scene_state := _get_scene_state(scene_root.scene_file_path, true)
	if torch.placed_by_player:
		var remaining = []
		for placed_torch in scene_state.get("placed", []):
			if int(placed_torch.get("id", -1)) != torch.placement_id:
				remaining.append(placed_torch)
		scene_state["placed"] = remaining
	else:
		var original_key := str(scene_root.get_path_to(torch))
		var removed = scene_state.get("removed", [])
		if not removed.has(original_key):
			removed.append(original_key)
		scene_state["removed"] = removed
	_store_scene_state(scene_root.scene_file_path, scene_state)


func restore_current_scene() -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null or scene_root.scene_file_path.is_empty():
		return
	var scene_id := scene_root.get_instance_id()
	if scene_id == restored_scene_id:
		return
	restored_scene_id = scene_id
	var scene_state := _get_scene_state(scene_root.scene_file_path, false)
	if scene_state.is_empty():
		return
	_remove_saved_original_torches(scene_root, scene_state.get("removed", []))
	for placed_torch in scene_state.get("placed", []):
		_spawn_placed_torch(
			scene_root,
			Vector2(float(placed_torch.get("x", 0.0)), float(placed_torch.get("y", 0.0))),
			int(placed_torch.get("id", -1))
		)


func _remove_saved_original_torches(scene_root: Node, removed_torches: Array) -> void:
	for torch_path in removed_torches:
		var original_torch := scene_root.get_node_or_null(NodePath(str(torch_path)))
		if original_torch != null:
			original_torch.hide()
			original_torch.queue_free()


func _spawn_placed_torch(level_root: Node2D, position: Vector2, placement_id: int) -> void:
	var torch_scene := load(TORCH_SCENE_PATH) as PackedScene
	if torch_scene == null:
		return
	var torch := torch_scene.instantiate()
	torch.configure_as_placed(placement_id)
	level_root.add_child(torch)
	torch.global_position = position


func _get_scene_state(scene_path: String, create_if_missing: bool) -> Dictionary:
	var all_states: Dictionary = SaveManager.current_save.get("torches", {})
	if not all_states.has(scene_path):
		if not create_if_missing:
			return {}
		all_states[scene_path] = {"removed": [], "placed": [], "next_id": 0}
		SaveManager.current_save["torches"] = all_states
	return all_states[scene_path]


func _store_scene_state(scene_path: String, scene_state: Dictionary) -> void:
	var all_states: Dictionary = SaveManager.current_save.get("torches", {})
	all_states[scene_path] = scene_state
	SaveManager.current_save["torches"] = all_states
