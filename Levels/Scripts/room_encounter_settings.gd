class_name RoomEncounterSettings extends Node

@export var threat_budget_override := -1
@export var floor_budgets: Array[int] = [4, 6, 8, 10, 12]


func _ready() -> void:
	add_to_group("room_encounter_settings")


func get_threat_budget(floor_number: int) -> int:
	if threat_budget_override >= 0:
		return threat_budget_override
	if floor_budgets.is_empty():
		return 0
	return floor_budgets[clampi(floor_number - 1, 0, floor_budgets.size() - 1)]
