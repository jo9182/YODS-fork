class_name SkillTreeMenu extends CanvasLayer

signal closed

# these must match skill_tree_lines.gd
const CELL_W = 65
const CELL_H = 45
const CELL_PAD = 18

# colour palette -- dark dungeon theme
const COL_BG          = Color(0.07, 0.08, 0.11, 0.97)
const COL_BORDER      = Color(0.55, 0.44, 0.14)       # dull gold border on panel
const COL_BTN_NORMAL  = Color(0.13, 0.14, 0.18)       # dark stone
const COL_BTN_BORDER  = Color(0.45, 0.36, 0.10)       # gold outline
const COL_BTN_LOCKED  = Color(0.10, 0.10, 0.12)       # nearly black
const COL_BTN_BOUGHT  = Color(0.10, 0.22, 0.12)       # dark green
const COL_BTN_BROKE   = Color(0.22, 0.10, 0.10)       # dark red -- can see but can't afford

var skill_tree: SkillTreeData
var description_label: Label
var gold_label: Label
var lines_node: SkillTreeLines
var buttons_node: Control        # sits on top of lines_node, same size
var skill_buttons: Dictionary = {}


func setup(data: SkillTreeData) -> void:
	skill_tree = data
	await ready
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	# escape closes the menu without bubbling up to the pause menu
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()


func close() -> void:
	closed.emit()


func _build_ui() -> void:
	# dark overlay behind everything
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.65)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# main panel
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(460, 262)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var panel_style = _make_flat_style(COL_BG, COL_BORDER, 6)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# title
	var title = Label.new()
	title.text = "— Skill Tree —"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "Altar Upgrades"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.9, 0.78, 0.3))
	vbox.add_child(title)

	gold_label = Label.new()
	gold_label.text = "Gold: %d" % PlayerStats.gold
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 10)
	gold_label.add_theme_color_override("font_color", Color(0.75, 0.68, 0.5))
	vbox.add_child(gold_label)

	# scroll container for the tree canvas
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(440, 160)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(scroll)

	# figure out canvas size from skill positions
	var max_col = 0
	var max_row = 0
	for skill in skill_tree.skills:
		max_col = max(max_col, skill.tree_column)
		max_row = max(max_row, skill.tree_row)

	var canvas_w = (max_col + 1) * (CELL_W + CELL_PAD) + CELL_PAD
	var canvas_h = (max_row + 1) * (CELL_H + CELL_PAD) + CELL_PAD
	var canvas_size = Vector2(canvas_w, canvas_h)

	# outer container so lines and buttons sit at the same coords
	var canvas = Control.new()
	canvas.custom_minimum_size = canvas_size
	canvas.size = canvas_size
	scroll.add_child(canvas)

	# lines draw FIRST (behind buttons)
	lines_node = SkillTreeLines.new()
	lines_node.custom_minimum_size = canvas_size
	lines_node.size = canvas_size
	lines_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(lines_node)
	lines_node.setup(skill_tree.skills)

	# buttons sit on top
	buttons_node = Control.new()
	buttons_node.custom_minimum_size = canvas_size
	buttons_node.size = canvas_size
	buttons_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(buttons_node)

	for skill in skill_tree.skills:
		_add_skill_button(skill)

	# description label below the scroll area
	description_label = Label.new()
	description_label.custom_minimum_size = Vector2(440, 26)
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	description_label.add_theme_font_size_override("font_size", 11)
	description_label.add_theme_color_override("font_color", Color(0.75, 0.68, 0.5))
	description_label.text = "Hover a skill to read about it"
	vbox.add_child(description_label)

	# close button
	var close_btn = Button.new()
	close_btn.text = "Close [Esc]"
	close_btn.add_theme_stylebox_override("normal", _make_flat_style(Color(0.15, 0.1, 0.08), Color(0.5, 0.35, 0.1), 4))
	close_btn.add_theme_color_override("font_color", Color(0.85, 0.7, 0.3))
	close_btn.pressed.connect(_on_close_pressed)
	vbox.add_child(close_btn)

	SkillTreeManager.skill_purchased.connect(_on_skill_purchased)
	PlayerStats.gold_changed.connect(_on_gold_changed)


func _add_skill_button(skill: SkillData) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(CELL_W, CELL_H)
	btn.size = Vector2(CELL_W, CELL_H)
	btn.position = Vector2(
		CELL_PAD + skill.tree_column * (CELL_W + CELL_PAD),
		CELL_PAD + skill.tree_row * (CELL_H + CELL_PAD)
	)
	btn.text = "%s\n%dg" % [skill.skill_name, skill.cost]
	btn.add_theme_font_size_override("font_size", 9)
	btn.clip_text = true

	if skill.icon:
		btn.icon = skill.icon

	buttons_node.add_child(btn)
	skill_buttons[skill.id] = btn

	btn.pressed.connect(_on_skill_button_pressed.bind(skill))
	btn.mouse_entered.connect(_on_skill_hovered.bind(skill))

	_update_button_state(skill, btn)


func _update_button_state(skill: SkillData, btn: Button) -> void:
	if SkillTreeManager.is_purchased(skill.id):
		btn.add_theme_stylebox_override("normal", _make_flat_style(COL_BTN_BOUGHT, Color(0.2, 0.7, 0.25), 4))
		btn.add_theme_stylebox_override("disabled", _make_flat_style(COL_BTN_BOUGHT, Color(0.2, 0.7, 0.25), 4))
		btn.add_theme_color_override("font_color", Color(0.5, 0.95, 0.55))
		btn.disabled = true
	elif SkillTreeManager.is_unlocked(skill):
		if PlayerStats.can_afford(skill.cost):
			# ready to buy -- gold bordered stone button
			btn.add_theme_stylebox_override("normal", _make_flat_style(COL_BTN_NORMAL, COL_BTN_BORDER, 4))
			btn.add_theme_stylebox_override("hover", _make_flat_style(Color(0.2, 0.2, 0.26), Color(0.85, 0.68, 0.2), 4))
			btn.add_theme_color_override("font_color", Color(0.9, 0.82, 0.55))
			btn.disabled = false
		else:
			# unlocked but broke -- reddish tint
			btn.add_theme_stylebox_override("normal", _make_flat_style(COL_BTN_BROKE, Color(0.5, 0.2, 0.2), 4))
			btn.add_theme_color_override("font_color", Color(0.7, 0.45, 0.45))
			btn.disabled = false
	else:
		# locked -- dim and unclickable
		btn.add_theme_stylebox_override("normal", _make_flat_style(COL_BTN_LOCKED, Color(0.25, 0.25, 0.28), 4))
		btn.add_theme_stylebox_override("disabled", _make_flat_style(COL_BTN_LOCKED, Color(0.25, 0.25, 0.28), 4))
		btn.add_theme_color_override("font_color", Color(0.35, 0.35, 0.38))
		btn.disabled = true


# helper to avoid repeating StyleBoxFlat setup everywhere
func _make_flat_style(bg: Color, border: Color, radius: int = 4) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(radius)
	return s


func _refresh_all_buttons() -> void:
	for skill in skill_tree.skills:
		if skill_buttons.has(skill.id):
			_update_button_state(skill, skill_buttons[skill.id])
	if is_instance_valid(lines_node):
		lines_node.refresh()


func _on_skill_button_pressed(skill: SkillData) -> void:
	if SkillTreeManager.is_purchased(skill.id):
		return
	if not SkillTreeManager.is_unlocked(skill):
		description_label.text = "You need to buy the prerequisite skill first."
		return
	if not PlayerStats.can_afford(skill.cost):
		description_label.text = "Not enough gold! (need %d, have %d)" % [skill.cost, PlayerStats.gold]
		return
	SkillTreeManager.try_buy(skill)


func _on_skill_hovered(skill: SkillData) -> void:
	var status = ""
	if SkillTreeManager.is_purchased(skill.id):
		status = "  ✓ Purchased"
	elif not SkillTreeManager.is_unlocked(skill):
		status = "  🔒 Locked"
	elif not PlayerStats.can_afford(skill.cost):
		status = "  ✗ Not enough gold"
	description_label.text = "%s — %s%s" % [skill.skill_name, skill.description, status]


func _on_skill_purchased(_skill: SkillData) -> void:
	_refresh_all_buttons()


func _on_gold_changed(new_amount: int) -> void:
	if gold_label != null:
		gold_label.text = "Gold: %d" % new_amount
	_refresh_all_buttons()


func _on_close_pressed() -> void:
	closed.emit()
