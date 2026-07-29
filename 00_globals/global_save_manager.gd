extends Node

const SAVE_PATH = "user://"

signal game_loaded
signal game_saved

var current_save: Dictionary = {
	scene_path = "",
	player = {
		hp = 1,
		max_hp = 1,
		pos_x = 0,
		pos_y = 0
	},
	gold = 0,
	# list of skill ids the player has bought
	purchased_skills = [],
	items = [],
	persistience = [],
	quest = [],
	chests = [],
	torches = {},
}


func save_game() -> void:
	update_player_data()
	update_scene_path()
	update_item_data()
	current_save.gold = PlayerStats.gold
	current_save.purchased_skills = SkillTreeManager.get_save_data()
	current_save.reputation = ReputationManager.get_save_data()
	current_save.shop_log = ShopLog.get_save_data()
	var file := FileAccess.open(SAVE_PATH + "save.sav", FileAccess.WRITE)
	var save_json = JSON.stringify(current_save)
	file.store_line(save_json)
	game_saved.emit()
	print("save_game")


func get_save_file() -> FileAccess:
	return FileAccess.open(SAVE_PATH + "save.sav", FileAccess.READ)


func load_game() -> void:
	var file := get_save_file()
	var json := JSON.new()
	json.parse(file.get_line())
	var save_dict: Dictionary = json.get_data() as Dictionary
	current_save = save_dict

	LevelManager.load_new_level(current_save.scene_path, "", Vector2.ZERO)
	#Modify the player
	await LevelManager.level_load_started

	PlayerManager.set_player_position(Vector2(current_save.player.pos_x, current_save.player.pos_y))
	PlayerManager.set_health(current_save.player.hp, current_save.player.max_hp)
	PlayerManager.INVENTORY_DATA.parseSave(current_save.items)
	PlayerStats.gold = current_save.get("gold", 0)
	ReputationManager.load_save_data(current_save.get("reputation", {}))
	ShopLog.load_save_data(current_save.get("shop_log", []))

	# restore skill purchases and re-apply their effects
	# we need to find all skills across the scene to pass to the manager
	# they live on the altar -- grab them from the current scene tree
	var all_skills = _find_all_skills()
	SkillTreeManager.load_save_data(current_save.get("purchased_skills", []), all_skills)

	await LevelManager.level_loaded
	print("load game")


func update_player_data() -> void:
	var p: Player = PlayerManager.player
	current_save.player.hp = p.hp
	current_save.player.max_hp = p.max_hp
	current_save.player.pos_x = p.global_position.x
	current_save.player.pos_y = p.global_position.y


func update_scene_path() -> void:
	var p: String = ""
	for c in get_tree().root.get_children():
		if c is level:
			p = c.scene_file_path
		current_save.scene_path = p


# searches the scene tree for an altar_interact node to get all SkillData from
# this works because SkillTreeData is assigned to the altar in the inspector
func _find_all_skills() -> Array[SkillData]:
	for node in get_tree().get_nodes_in_group("altar"):
		if node.has_method("get") and node.get("skill_tree") != null:
			return node.skill_tree.skills
	# fallback -- just return empty if the altar isn't in the current scene
	# skills will still be marked as purchased, effects just won't re-apply until
	# the player visits the altar room
	return []

func update_item_data() -> void:
	current_save.items = PlayerManager.INVENTORY_DATA.getSaveData()

func add_persistent_value(value : String) -> void:
	if check_persistent_value(value) == false:
		#If not in the array then we add it
		current_save.persistience.append(value)
	pass
	
func check_persistent_value(value : String) -> bool:
	#Gets a persistence varialbe in an Array
	var p = current_save.persistience as Array
	#Does the array have the value
	return p.has(value)
	pass
