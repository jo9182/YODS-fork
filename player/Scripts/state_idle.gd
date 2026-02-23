class_name State_Idle extends State

@onready var walk: State = $"../walk"
@onready var attack: State = $"../attack"
@onready var ranged: State = $"../ranged"


func enter() -> void:
	player.updateAnimation("idle")


func exit() -> void:
	pass


func process(_delta: float) -> State:
	if player.direction != Vector2.ZERO:
		return walk
	player.velocity = Vector2.ZERO
	return null


func physics(_delta: float) -> State:
	return null


func handleInput(_event: InputEvent) -> State:
	if _event.is_action_pressed("Attack"):
		return attack
	if _event.is_action_pressed("ranged"):
		return ranged
	return null
