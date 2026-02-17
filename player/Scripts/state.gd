class_name State extends Node

## Stores reference to the player that this state belongs to
static var player : Player
static var state_machine : PlayerStateMachine

func init() -> void:
	pass

func _ready():
	pass

## what happens when the player enters this state
func enter() -> void:
	pass
	
## what happens when the player exits this state
func exit() -> void:
	pass
	
## what happens during the process in this state
func process( _delta : float) -> State:
	return null
	
## what happens during the physics process in this state
func physics(_delta : float) -> State:
	return null

## what happens with input events in this state
func handleInput(_event : InputEvent) -> State:
	return null
