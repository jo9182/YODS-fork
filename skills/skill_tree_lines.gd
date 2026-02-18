class_name SkillTreeLines extends Control

# same constants as skill_tree_menu -- must stay in sync
const CELL_W = 65
const CELL_H = 45
const CELL_PAD = 18

var skill_positions: Dictionary = {}
var skills: Array[SkillData] = []


func setup(skill_list: Array[SkillData]) -> void:
	skills = skill_list
	for skill in skills:
		skill_positions[skill.id] = _get_center(skill)
	queue_redraw()


func refresh() -> void:
	queue_redraw()


func _get_center(skill: SkillData) -> Vector2:
	return Vector2(
		CELL_PAD + skill.tree_column * (CELL_W + CELL_PAD) + CELL_W * 0.5,
		CELL_PAD + skill.tree_row * (CELL_H + CELL_PAD) + CELL_H * 0.5
	)


func _draw() -> void:
	for skill in skills:
		for prereq_id in skill.prerequisite_ids:
			if not skill_positions.has(prereq_id) or not skill_positions.has(skill.id):
				continue

			var from: Vector2 = skill_positions[prereq_id]
			var to: Vector2 = skill_positions[skill.id]

			# bright gold if prereq is bought, dim grey if not
			var col = Color(0.35, 0.35, 0.35)
			var width = 2.0
			if SkillTreeManager.is_purchased(prereq_id):
				col = Color(0.9, 0.72, 0.1)
				width = 2.5

			draw_line(from, to, col, width)
