class_name level extends Node2D

func _ready() -> void:
	self.y_sort_enabled = true
	PlayerManager.set_as_parent(self)
	LevelManager.level_load_started.connect( free_level )
	pass
	
func free_level() -> void:
	PlayerManager.unparent_player(self)
	queue_free()
	pass
