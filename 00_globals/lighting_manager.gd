extends Node

const FLOOR_AMBIENT := {
	"Area_1": Color(0.7, 0.64, 0.76, 1.0),
	"Area_2": Color(0.52, 0.47, 0.64, 1.0),
	"Area_3": Color(0.35, 0.34, 0.52, 1.0),
	"Area_4": Color(0.2, 0.23, 0.36, 1.0),
	"Area_5": Color(0.06, 0.08, 0.14, 1.0),
}


func _ready() -> void:
	get_tree().scene_changed.connect(_apply_floor_lighting)
	call_deferred("_apply_current_scene_lighting")


func _apply_current_scene_lighting() -> void:
	_apply_floor_lighting(get_tree().current_scene)


func _apply_floor_lighting(scene_root: Node) -> void:
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
