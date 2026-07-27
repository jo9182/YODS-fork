class_name persistence extends Node

signal data_loaded
var value : bool = false

func _ready() -> void:
	getValue()
	pass
	
func setValue() -> void:
	#Sets our variable to true or false using two methods.
	SaveManager.add_persistent_value(_getName())
	pass
	
func getValue() -> void:
	#checks our variable equal to true or false whether the chest is open or not
	value = SaveManager.check_persistent_value(_getName())
	data_loaded.emit()
	pass

func _getName() -> String:
	#This gets the name of the current scene in a resource format (res://) + Gets the name of the parent node
	return get_tree().current_scene.scene_file_path + "/" + get_parent().name + "/" + name
