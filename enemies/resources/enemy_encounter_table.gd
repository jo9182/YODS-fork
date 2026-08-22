class_name EnemyEncounterTable extends Resource

@export var table_id := ""
@export var entries: Array[EnemyEncounterEntry] = []


func get_available_entries(floor_number: int) -> Array[EnemyEncounterEntry]:
	var available: Array[EnemyEncounterEntry] = []
	for entry in entries:
		if entry != null and entry.is_available(floor_number):
			available.append(entry)
	return available


func choose_entry(floor_number: int, random: RandomNumberGenerator) -> EnemyEncounterEntry:
	var available := get_available_entries(floor_number)
	if available.is_empty():
		return null
	var total_weight := 0.0
	for entry in available:
		total_weight += entry.weight
	if total_weight <= 0.0:
		return available[0]
	var roll := random.randf_range(0.0, total_weight)
	for entry in available:
		roll -= entry.weight
		if roll <= 0.0:
			return entry
	return available[-1]

