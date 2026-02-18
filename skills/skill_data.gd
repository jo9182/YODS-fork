class_name SkillData extends Resource

# name shown in the menu
@export var skill_name: String = ""

# description shown when the skill is focused
@export_multiline var description: String = ""

# gold cost to buy this
@export var cost: int = 50

# optional icon -- leave blank and it'll just show the name
@export var icon: Texture2D = null

# where this skill sits in the visual grid
# column 0 is leftmost, row 0 is topmost
@export var tree_column: int = 0
@export var tree_row: int = 0

# ids of skills that must be bought before this one unlocks
# just use the skill_name as the id for simplicity
@export var prerequisite_ids: Array[String] = []

# what actually happens when this skill is bought
# hp_max    -- increases max hp by effect_value
# speed     -- adds effect_value to movement speed
# damage    -- adds effect_value to attack damage
# shop_slots -- adds effect_value more listing slots to the shop
# custom    -- does nothing automatically, handle it via SkillTreeManager.skill_purchased signal
@export_enum("hp_max", "speed", "damage", "shop_slots", "custom") var effect_type: String = "custom"
@export var effect_value: float = 1.0

# unique id -- just set this to the skill name, needs to be unique across all skills
@export var id: String = ""
