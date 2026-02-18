extends Area2D

# drag your SkillTreeData .tres here in the inspector
@export var skill_tree: SkillTreeData

# is the player currently standing inside the altar area
var player_inside: bool = false

var menu_open: bool = false
var menu_instance: SkillTreeMenu = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_inside = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_inside = false
		# close the menu if they wander out
		if menu_open:
			_close_menu()


func _unhandled_input(event: InputEvent) -> void:
	if not player_inside:
		return

	if event.is_action_pressed("interact"):
		if menu_open:
			_close_menu()
		else:
			_open_menu()


func _open_menu() -> void:
	if skill_tree == null:
		push_error("altar_interact: no SkillTreeData assigned in the inspector!")
		return

	menu_open = true
	get_tree().paused = true

	menu_instance = SkillTreeMenu.new()
	menu_instance.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_instance.setup(skill_tree)
	menu_instance.closed.connect(_close_menu)
	get_tree().root.add_child(menu_instance)


func _close_menu() -> void:
	menu_open = false
	get_tree().paused = false
	if is_instance_valid(menu_instance):
		menu_instance.queue_free()
	menu_instance = null
