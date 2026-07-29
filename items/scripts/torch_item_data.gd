class_name TorchItemData extends ItemData

const TORCH_SCENE := preload("res://Props/torch/torch.tscn")


func use() -> bool:
	if PlayerManager.player == null:
		return false
	var level_root := PlayerManager.player.get_parent()
	if level_root == null:
		return false
	var torch := TORCH_SCENE.instantiate()
	level_root.add_child(torch)
	torch.global_position = PlayerManager.player.global_position
	return true
