extends CanvasLayer

var is_open: bool = false

@onready var gold_label: Label = $Control/Panel/GoldLabel
@onready var craft_rows: VBoxContainer = $Control/Panel/CraftRows
@onready var upgrade_rows: VBoxContainer = $Control/Panel/UpgradeRows


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	CraftingManager.recipe_crafted.connect(_on_recipe_crafted)
	ShopUpgradeManager.upgrades_changed.connect(_refresh)
	PlayerStats.gold_changed.connect(_on_gold_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("craft"):
		if is_open:
			close()
		elif ShopManager.in_shop_zone:
			open()
		else:
			return
		get_viewport().set_input_as_handled()
		return
	if is_open and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	if not ShopManager.in_shop_zone:
		return
	var menu_manager := get_node_or_null("/root/MenuManager")
	if menu_manager != null:
		menu_manager.call("open", self)
	is_open = true
	visible = true
	get_tree().paused = true
	_refresh()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	var menu_manager := get_node_or_null("/root/MenuManager")
	if menu_manager != null:
		menu_manager.call("close", self)
	get_tree().paused = false


func _refresh() -> void:
	if not is_open:
		return
	gold_label.text = "Gold: %d" % PlayerStats.gold
	_rebuild_recipes()
	_rebuild_upgrades()


func _rebuild_recipes() -> void:
	_clear_rows(craft_rows)
	for entry in CraftingManager.get_recipes():
		var recipe: Dictionary = entry
		var button := Button.new()
		button.custom_minimum_size = Vector2(190.0, 38.0)
		button.add_theme_font_size_override("font_size", 9)
		button.text = "%s\n%s -> %s" % [
			str(recipe.get("name", "Recipe")),
			CraftingManager.get_ingredient_text(recipe),
			CraftingManager.get_output_text(recipe),
		]
		button.disabled = not CraftingManager.can_craft(str(recipe.get("id", "")))
		button.pressed.connect(_on_recipe_pressed.bind(str(recipe.get("id", ""))))
		craft_rows.add_child(button)


func _rebuild_upgrades() -> void:
	_clear_rows(upgrade_rows)
	for entry in ShopUpgradeManager.get_upgrades():
		var upgrade: Dictionary = entry
		var upgrade_id: String = str(upgrade.get("id", ""))
		var purchased: bool = ShopUpgradeManager.is_purchased(upgrade_id)
		var cost: int = int(upgrade.get("cost", 0))
		var button := Button.new()
		button.custom_minimum_size = Vector2(190.0, 38.0)
		button.add_theme_font_size_override("font_size", 9)
		button.text = "%s - %s\n%s" % [
			str(upgrade.get("name", "Upgrade")),
			"Owned" if purchased else "%dg" % cost,
			str(upgrade.get("description", "")),
		]
		button.disabled = purchased or not PlayerStats.can_afford(cost)
		button.pressed.connect(_on_upgrade_pressed.bind(upgrade_id))
		upgrade_rows.add_child(button)


func _clear_rows(container: VBoxContainer) -> void:
	for child in container.get_children():
		child.queue_free()


func _on_recipe_pressed(recipe_id: String) -> void:
	CraftingManager.craft(recipe_id)
	_refresh()


func _on_upgrade_pressed(upgrade_id: String) -> void:
	ShopUpgradeManager.purchase(upgrade_id)
	_refresh()


func _on_recipe_crafted(_recipe_id: String) -> void:
	_refresh()


func _on_gold_changed(_new_amount: int) -> void:
	_refresh()
