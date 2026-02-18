## register as autoload: SkillTreeManager
## path: res://skills/skill_tree_manager.gd

extends Node

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
	_apply_effect(skill)
	skill_purchased.emit(skill)
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
		"custom":
			# nothing automatic happens -- listen to skill_purchased signal yourself
			pass


# called by the save manager to get what needs saving
func get_save_data() -> Array[String]:
	return purchased_skills.duplicate()


# called on load -- re-applies all purchased skill effects
# note: hp_max is skipped here because max_hp is already restored from the save file
func load_save_data(data: Array, all_skills: Array[SkillData]) -> void:
	purchased_skills = []
	for id in data:
		purchased_skills.append(str(id))

	for skill in all_skills:
		if is_purchased(skill.id) and skill.effect_type != "hp_max":
			_apply_effect(skill)
