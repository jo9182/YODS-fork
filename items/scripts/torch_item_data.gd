class_name TorchItemData extends ItemData


func use() -> bool:
	if PlayerManager.player == null:
		return false
	var level_root := PlayerManager.player.get_parent()
	if level_root == null:
		return false
	var scene_tree := Engine.get_main_loop() as SceneTree
	if scene_tree == null:
		return false
	var torch_manager := scene_tree.root.get_node_or_null("TorchManager")
	if torch_manager == null:
		return false
	return torch_manager.place_torch(level_root, PlayerManager.player.global_position)
