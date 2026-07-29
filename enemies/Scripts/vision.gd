class_name vision extends Area2D

signal target_arrived(target: Node2D)
signal target_left(target: Node2D)

func _ready() -> void:
	body_entered.connect(_on_body_enter)
	body_exited.connect(_on_body_exit)
	
	var p = get_parent()
	if p is Enemy:
		p.DirectionChanged.connect(_on_Direction_changed)
	
func _on_body_enter(body: Node2D) -> void:
	if body is Player or body.is_in_group("dungeon_explorers"):
		target_arrived.emit(body)


func _on_body_exit(body: Node2D) -> void:
	if body is Player or body.is_in_group("dungeon_explorers"):
		target_left.emit(body)
	

func _on_Direction_changed( new_Dir : Vector2) -> void:
	match new_Dir:
		Vector2.DOWN:
			rotation_degrees = 0
		Vector2.UP:
			rotation_degrees = 180
		Vector2.LEFT:
			rotation_degrees = 90
		Vector2.RIGHT:
			rotation_degrees = -90
		_:
			rotation_degrees = 0
	pass
