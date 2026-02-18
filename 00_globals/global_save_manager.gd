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
	# gold is just a number now, much simpler
	gold = 0,
	items = [],
	persistience = [],
	quest = [],
	chests = [],
}

func save_game() -> void:
	update_player_data()
	update_scene_path()
	# grab gold from PlayerStats before writing
	current_save.gold = PlayerStats.gold
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

	await LevelManager.level_load_started

	PlayerManager.set_player_position(Vector2(current_save.player.pos_x, current_save.player.pos_y))
	PlayerManager.set_health(current_save.player.hp, current_save.player.max_hp)

	# restore gold -- default to 0 if the save is old and doesn't have it yet
	PlayerStats.gold = current_save.get("gold", 0)

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
