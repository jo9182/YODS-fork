class_name TestLab extends level

const TILE_SOURCE_ID := 2
const TILE_COORDINATES := Vector2i(0, 0)
const ROOM_CELLS := Rect2i(0, 2, 15, 9)
const EXPLORER_SCENE := preload("res://NPC's/dungeon_explorer.tscn")
const SLIME_SCENE := preload("res://enemies/slime/slime.tscn")
const VAMPIRE_SCENE := preload("res://enemies/vampire.tscn")
const SKELETON_SCENE := preload("res://enemies/skeleton.tscn")
const PICKUP_SCENE := preload("res://items/item_pickup/item_pickup.tscn")
const STONE := preload("res://items/stone.tres")
const SLIME_RESIDUE := preload("res://items/slime_residue.tres")
const VAMPIRE_TOOTH := preload("res://items/vamp_tooth.tres")
const TORCH := preload("res://items/torch.tres")
const POTION := preload("res://items/potion.tres")
const GEM := preload("res://items/gem.tres")
const APPLE := preload("res://items/apple.tres")

const AREA_SURVEY_SCENES := [
	"res://Levels/Area_1/01.tscn",
	"res://Levels/Area_2/dungeon_02.tscn",
	"res://Levels/Area_3/dungeon_03.tscn",
	"res://Levels/Area_4/dungeon_04.tscn",
	"res://Levels/Area_5/dungeon_05.tscn",
]

@onready var test_tilemap: TileMapLayer = $TestTileMap
@onready var customer_manager: CustomerManager = $CustomerManager

var status_label: Label


func _ready() -> void:
	super()
	SaveManager.set_test_session(true)
	_prepare_navigation_floor()
	_create_boundary_walls()
	_build_overlay()
	PlayerManager.set_player_position($PlayerSpawn.global_position)
	ShopManager.in_shop_zone = true
	_stock_shop()
	call_deferred("_refresh_test_systems")
	_show_status("Ready: F1 grants a full testing loadout.")


func _exit_tree() -> void:
	if SaveManager != null:
		SaveManager.set_test_session(false)


func _draw() -> void:
	draw_rect(Rect2(0, 64, 480, 288), Color(0.055, 0.07, 0.1, 1.0))
	draw_rect(Rect2(18, 82, 444, 236), Color(0.1, 0.14, 0.2, 1.0), false, 3.0)
	draw_rect(Rect2(204, 212, 252, 50), Color(0.17, 0.12, 0.08, 0.95))
	draw_rect(Rect2(278, 96, 160, 94), Color(0.16, 0.08, 0.09, 0.72), false, 2.0)
	draw_rect(Rect2(32, 96, 142, 84), Color(0.08, 0.16, 0.12, 0.72), false, 2.0)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_F1:
			_grant_supplies()
		KEY_F2:
			_spawn_test_party()
		KEY_F3:
			_spawn_enemy_wave()
		KEY_F4:
			_spawn_pickup_row()
		KEY_F5:
			_add_commission_offer()
		KEY_F6:
			_survey_all_areas()
		KEY_F7:
			_place_test_torch()
		KEY_F8:
			_summon_tax_collector()
		KEY_F9:
			_stock_shop()
		KEY_F10:
			_reset_enemy_encounters()
		_:
			return
	get_viewport().set_input_as_handled()


func _prepare_navigation_floor() -> void:
	for cell_x in range(ROOM_CELLS.position.x, ROOM_CELLS.end.x):
		for cell_y in range(ROOM_CELLS.position.y, ROOM_CELLS.end.y):
			test_tilemap.set_cell(Vector2i(cell_x, cell_y), TILE_SOURCE_ID, TILE_COORDINATES)
	var used_rect := test_tilemap.get_used_rect()
	LevelManager.ChangeTilemapBounds([
		Vector2(used_rect.position * test_tilemap.rendering_quadrant_size),
		Vector2(used_rect.end * test_tilemap.rendering_quadrant_size),
	])


func _create_boundary_walls() -> void:
	_create_wall(Vector2(240, 66), Vector2(480, 12))
	_create_wall(Vector2(240, 350), Vector2(480, 12))
	_create_wall(Vector2(6, 208), Vector2(12, 284))
	_create_wall(Vector2(474, 208), Vector2(12, 284))


func _create_wall(wall_position: Vector2, wall_size: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = 16
	wall.collision_mask = 0
	wall.position = wall_position
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = wall_size
	collision.shape = shape
	wall.add_child(collision)
	add_child(wall)


func _refresh_test_systems() -> void:
	await get_tree().physics_frame
	DungeonPathfinder._rebuild_for_active_scene()
	DungeonLifeManager._populate_explorers()


func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	var panel := ColorRect.new()
	panel.position = Vector2(4, 4)
	panel.size = Vector2(190, 262)
	panel.color = Color(0.025, 0.03, 0.05, 0.9)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	var instructions := Label.new()
	instructions.position = Vector2(10, 8)
	instructions.size = Vector2(178, 218)
	instructions.add_theme_font_size_override("font_size", 8)
	instructions.text = "TEST LAB\nSave writes disabled\n\nI inventory/list items\nC workshop, Q commissions\nM map, L shop log\n\nF1 loadout   F2 party\nF3 enemies   F4 pickups\nF5 job       F6 survey\nF7 torch     F8 Tax Collector\nF9 stock shop  F10 reset enemies"
	instructions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(instructions)
	status_label = Label.new()
	status_label.position = Vector2(10, 232)
	status_label.size = Vector2(178, 26)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.42, 1.0))
	status_label.add_theme_font_size_override("font_size", 8)
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(status_label)
	add_child(layer)


func _show_status(message: String) -> void:
	if status_label != null:
		status_label.text = message


func _grant_supplies() -> void:
	_add_inventory_item(STONE, 24)
	_add_inventory_item(SLIME_RESIDUE, 18)
	_add_inventory_item(VAMPIRE_TOOTH, 12)
	_add_inventory_item(TORCH, 24)
	_add_inventory_item(POTION, 12)
	_add_inventory_item(GEM, 8)
	_add_inventory_item(APPLE, 12)
	PlayerStats.add_gold(1000)
	if PlayerManager.player != null:
		PlayerManager.player.update_hp(PlayerManager.player.max_hp)
		PlayerManager.player.refresh_lantern()
	_show_status("Supplies, 1000 gold, health, and lantern charge granted.")


func _add_inventory_item(item_data: ItemData, amount: int) -> void:
	PlayerManager.INVENTORY_DATA.addItem(item_data, amount)


func _stock_shop() -> void:
	ShopManager.add_listing(STONE, 2)
	ShopManager.add_listing(TORCH, 4)
	ShopManager.add_listing(POTION, 16)
	ShopManager.add_listing(GEM, 55)
	_show_status("Shelf stocked. Customers should begin purchasing shortly.")


func _spawn_test_party() -> void:
	var leader := _spawn_explorer(Vector2(248, 136), 2)
	if leader == null:
		return
	leader.configure_party(leader, 0, "Test")
	var scout := _spawn_explorer(Vector2(224, 152), 2)
	if scout != null:
		scout.configure_party(leader, 1, "Test")
	var guard := _spawn_explorer(Vector2(272, 152), 2)
	if guard != null:
		guard.configure_party(leader, 2, "Test")
	_show_status("Spawned a three-person adventurer party.")


func _spawn_explorer(spawn_position: Vector2, floor_number: int) -> DungeonExplorer:
	var explorer := EXPLORER_SCENE.instantiate() as DungeonExplorer
	if explorer == null:
		return null
	add_child(explorer)
	explorer.setup(spawn_position, floor_number)
	return explorer


func _spawn_enemy_wave() -> void:
	_spawn_enemy(SLIME_SCENE, Vector2(376, 124))
	_spawn_enemy(VAMPIRE_SCENE, Vector2(402, 156))
	_spawn_enemy(SKELETON_SCENE, Vector2(376, 188))
	_show_status("Spawned slime, vampire, and skeleton combat targets.")


func _spawn_enemy(enemy_scene: PackedScene, spawn_position: Vector2) -> void:
	var enemy_manager := get_node_or_null("/root/DungeonEnemyManager")
	if enemy_manager != null and enemy_manager.has_method("spawn_enemy"):
		enemy_manager.call("spawn_enemy", enemy_scene, spawn_position)
		return
	var enemy := enemy_scene.instantiate() as Enemy
	if enemy == null:
		return
	enemy.position = spawn_position
	add_child(enemy)


func _reset_enemy_encounters() -> void:
	var enemy_manager := get_node_or_null("/root/DungeonEnemyManager")
	if enemy_manager != null and enemy_manager.has_method("reset_current_room_state"):
		enemy_manager.call("reset_current_room_state")
		_show_status("Reset authored encounters for this test room.")


func _spawn_pickup_row() -> void:
	var items: Array[ItemData] = [STONE, SLIME_RESIDUE, VAMPIRE_TOOTH, TORCH, POTION, GEM, APPLE]
	for index in items.size():
		_spawn_pickup(items[index], Vector2(286 + index * 24, 280))
	_show_status("Spawned one of every pickup for player and adventurer testing.")


func _spawn_pickup(item_data: ItemData, spawn_position: Vector2) -> void:
	var pickup := PICKUP_SCENE.instantiate() as item_pickup
	if pickup == null:
		return
	pickup.item_data = item_data
	pickup.position = spawn_position
	add_child(pickup)


func _add_commission_offer() -> void:
	for _visit in range(CommissionManager.CUSTOMER_VISITS_PER_COMMISSION):
		CommissionManager.record_customer_visit()
	_show_status("A customer commission was added if the board has room.")


func _survey_all_areas() -> void:
	for scene_path in AREA_SURVEY_SCENES:
		MapDiscoveryManager.discover_room(scene_path)
	_show_status("All five Areas marked as surveyed for commission testing.")


func _place_test_torch() -> void:
	if PlayerManager.player == null:
		return
	if TorchManager.place_torch(self, PlayerManager.player.global_position + Vector2(0, -20)):
		_show_status("Placed a persistent test torch beside the Goblin.")
	else:
		_show_status("Torch placement failed.")


func _summon_tax_collector() -> void:
	TaxDebtManager.loan_balance = maxi(TaxDebtManager.loan_balance, TaxDebtManager.STARTING_LOAN)
	TaxDebtManager.collector_visit_pending = true
	TaxDebtManager._store_in_save()
	customer_manager._spawn_tax_collector()
	_show_status("The Tax Collector has been requested at the shop entrance.")
