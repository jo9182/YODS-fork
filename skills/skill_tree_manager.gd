## register as autoload: SkillTreeManager
## path: res://skills/skill_tree_manager.gd

extends Node

const DEFAULT_SKILL_TREE: SkillTreeData = preload("res://skills/my_skill_tree.tres")

# fires when anything gets bought -- useful for custom skills
signal skill_purchased(skill: SkillData)

# ids of everything the player has bought so far
var purchased_skills: Array[String] = []


# has the player already bought this skill
func is_purchased(id: String) -> bool:
	return purchased_skills.has(id)


# can the player even see/click this skill yet
# (all prerequisites must be bought first)
func is_unlocked(skill: SkillData) -> bool:
	for prereq_id in skill.prerequisite_ids:
		if not is_purchased(prereq_id):
			print("LOCKED: '%s' requires '%s' -- purchased list: %s" % [skill.id, prereq_id, purchased_skills])
			return false
	return true


# try to buy a skill -- returns false if it fails for any reason
func try_buy(skill: SkillData) -> bool:
	if is_purchased(skill.id):
		return false
	if not is_unlocked(skill):
		return false
	# spend_gold returns false if the player can't afford it
	if not PlayerStats.spend_gold(skill.cost):
		return false

	purchased_skills.append(skill.id)
	print("PURCHASED: '%s' -- full list now: %s" % [skill.id, purchased_skills])
	_apply_effect(skill)
	skill_purchased.emit(skill)
	SaveManager.autosave_game()
	return true


# actually do the thing the skill says it does
func _apply_effect(skill: SkillData) -> void:
	match skill.effect_type:
		"hp_max":
			var player = PlayerManager.player
			player.max_hp += int(skill.effect_value)
			# heal the player by the same amount so it feels rewarding
			player.update_hp(int(skill.effect_value))
		"speed":
			PlayerStats.speed_bonus += skill.effect_value
		"damage":
			PlayerStats.damage_bonus += skill.effect_value
		"shop_slots":
			ShopManager.max_listings += int(skill.effect_value)
		"lantern":
			PlayerStats.lantern_energy_bonus += skill.effect_value
			PlayerStats.lantern_scale_bonus += skill.effect_value * 0.8
			if PlayerManager.player != null:
				PlayerManager.player.refresh_lantern()
		"torch_yield":
			CraftingManager.torch_bundle_bonus += int(skill.effect_value)
		"customer_speed":
			PlayerStats.customer_spawn_reduction += skill.effect_value
		"customer_budget":
			PlayerStats.customer_budget_bonus += skill.effect_value
		"renown":
			PlayerStats.fair_sale_renown_bonus += int(skill.effect_value)
		"explorer":
			PlayerStats.explorer_bonus += int(skill.effect_value)
		"custom":
			# nothing automatic happens -- listen to skill_purchased signal yourself
			pass


# called by the save manager to get what needs saving
func get_save_data() -> Array[String]:
	return purchased_skills.duplicate()


# called on load, re-applies all purchased skill effects
# note: hp_max is skipped here because max_hp is already restored from the save file
func load_save_data(data: Array, all_skills: Array[SkillData]) -> void:
	purchased_skills = []
	for id in data:
		purchased_skills.append(str(id))

	_reset_reapplied_effects()
	var skills_to_apply: Array[SkillData] = all_skills
	if skills_to_apply.is_empty():
		skills_to_apply = DEFAULT_SKILL_TREE.skills
	for skill in skills_to_apply:
		if is_purchased(skill.id) and skill.effect_type != "hp_max":
			_apply_effect(skill)
	if PlayerManager.player != null:
		PlayerManager.player.refresh_lantern()


func _reset_reapplied_effects() -> void:
	PlayerStats.speed_bonus = 0.0
	PlayerStats.damage_bonus = 0.0
	PlayerStats.lantern_energy_bonus = 0.0
	PlayerStats.lantern_scale_bonus = 0.0
	PlayerStats.customer_spawn_reduction = 0.0
	PlayerStats.customer_budget_bonus = 0.0
	PlayerStats.fair_sale_renown_bonus = 0
	PlayerStats.explorer_bonus = 0
	ShopManager.max_listings = 5
	CraftingManager.torch_bundle_bonus = 0
