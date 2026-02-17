class_name State_Idle extends State

@onready var walk: State = $"../walk"
@onready var attack: State = $"../attack"

## what happens when the player enters this state
func enter() -> void:
	player.updateAnimation("idle")
	pass
	
## what happens when the player exits this state
func exit() -> void:
	pass
	
## what happens during the process in this state
func process( _delta : float) -> State:
	if player.direction != Vector2.ZERO:
		return walk
	player.velocity = Vector2.ZERO
	return null
	
## what happens during the physics process in this state
func physics(_delta : float) -> State:
	return null

## what happens with input events in this state
func handleInput(_event : InputEvent) -> State:
	if _event.is_action_pressed("Attack"):
		return attack
	return null
