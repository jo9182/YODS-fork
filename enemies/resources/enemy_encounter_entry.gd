class_name EnemyEncounterEntry extends Resource

@export var enemy_scene: PackedScene
@export_range(0.01, 100.0, 0.01) var weight := 1.0
@export_range(1, 20, 1) var threat_cost := 1
@export var min_floor := 1
@export var max_floor := 5


func is_available(floor_number: int) -> bool:
	return enemy_scene != null and floor_number >= min_floor and floor_number <= max_floor and weight > 0.0

