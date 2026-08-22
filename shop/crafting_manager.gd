extends Node

signal recipe_crafted(recipe_id: String)

var torch_bundle_bonus: int = 0

const RECIPES := [
	{
		"id": "torch_bundle",
		"name": "Torch Bundle",
		"ingredients": [
			{"path": "res://items/slime_residue.tres", "amount": 1},
			{"path": "res://items/stone.tres", "amount": 1},
		],
		"output_path": "res://items/torch.tres",
		"output_amount": 2,
	},
	{
		"id": "healing_potion",
		"name": "Healing Potion",
		"ingredients": [
			{"path": "res://items/slime_residue.tres", "amount": 2},
			{"path": "res://items/vamp_tooth.tres", "amount": 1},
		],
		"output_path": "res://items/potion.tres",
		"output_amount": 1,
	},
	{
		"id": "polished_gem",
		"name": "Polished Gem",
		"ingredients": [
			{"path": "res://items/stone.tres", "amount": 3},
			{"path": "res://items/vamp_tooth.tres", "amount": 1},
		],
		"output_path": "res://items/gem.tres",
		"output_amount": 1,
	},
]


func get_recipes() -> Array:
	return RECIPES


func get_recipe(recipe_id: String) -> Dictionary:
	for entry in RECIPES:
		var recipe: Dictionary = entry
		if str(recipe.get("id", "")) == recipe_id:
			return recipe
	return {}


func can_craft(recipe_id: String) -> bool:
	var recipe: Dictionary = get_recipe(recipe_id)
	if recipe.is_empty():
		return false
	var output: ItemData = load(str(recipe.get("output_path", ""))) as ItemData
	if output == null:
		return false
	var inventory: inventoryData = PlayerManager.INVENTORY_DATA
	if not inventory.has_space_for(output):
		return false
	for entry in recipe.get("ingredients", []):
		var ingredient: Dictionary = entry
		var item: ItemData = load(str(ingredient.get("path", ""))) as ItemData
		var amount: int = int(ingredient.get("amount", 0))
		if item == null or inventory.get_item_count(item) < amount:
			return false
	return true


func craft(recipe_id: String) -> bool:
	if not can_craft(recipe_id):
		return false
	var recipe: Dictionary = get_recipe(recipe_id)
	var inventory: inventoryData = PlayerManager.INVENTORY_DATA
	for entry in recipe.get("ingredients", []):
		var ingredient: Dictionary = entry
		var item: ItemData = load(str(ingredient.get("path", ""))) as ItemData
		inventory.remove_item(item, int(ingredient.get("amount", 0)))
	var output: ItemData = load(str(recipe.get("output_path", ""))) as ItemData
	inventory.addItem(output, get_output_amount(recipe))
	recipe_crafted.emit(recipe_id)
	SaveManager.autosave_game()
	return true


func get_ingredient_text(recipe: Dictionary) -> String:
	var labels: Array[String] = []
	for entry in recipe.get("ingredients", []):
		var ingredient: Dictionary = entry
		var item: ItemData = load(str(ingredient.get("path", ""))) as ItemData
		var amount: int = int(ingredient.get("amount", 0))
		if item != null:
			labels.append("%dx %s" % [amount, item.name])
	return " + ".join(labels)


func get_output_text(recipe: Dictionary) -> String:
	var output: ItemData = load(str(recipe.get("output_path", ""))) as ItemData
	if output == null:
		return "Unknown"
	return "%dx %s" % [get_output_amount(recipe), output.name]


func get_output_amount(recipe: Dictionary) -> int:
	var amount: int = int(recipe.get("output_amount", 1))
	if str(recipe.get("id", "")) == "torch_bundle":
		amount += torch_bundle_bonus
	return amount
