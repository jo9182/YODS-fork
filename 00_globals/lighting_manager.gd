extends Node

const FLOOR_AMBIENT := {
	"Area_1": Color(0.66, 0.62, 0.72, 1.0),
	"Area_2": Color(0.45, 0.41, 0.55, 1.0),
	"Area_3": Color(0.26, 0.25, 0.4, 1.0),
	"Area_4": Color(0.11, 0.13, 0.2, 1.0),
	"Area_5": Color(0.012, 0.014, 0.025, 1.0),
}


func _ready() -> void:
	get_tree().scene_changed.connect(_apply_floor_lighting)
	call_deferred("_apply_floor_lighting")


func _apply_floor_lighting() -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return

	for floor_name in FLOOR_AMBIENT:
		if not scene_root.scene_file_path.begins_with("res://Levels/%s/" % floor_name):
			continue

		var ambient_light := scene_root.get_node_or_null("AmbientLight") as CanvasModulate
		if ambient_light == null:
			ambient_light = CanvasModulate.new()
			ambient_light.name = "AmbientLight"
			scene_root.add_child(ambient_light)
		ambient_light.color = FLOOR_AMBIENT[floor_name]
		return
