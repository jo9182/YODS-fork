class_name EnemyState extends Node

## Stores reference to the enemy that this state belongs to.
var enemy : Enemy
var state_machine : EnemyStateMachine



func _ready():
	pass
	
## What happens when you initalize this state
func init() -> void:
	pass
	
## what happens when the player enters this state
func enter() -> void:
	pass
	
## what happens when the player exits this state
func exit() -> void:
	pass
	
## what happens during the process in this state
func process( _delta : float) -> EnemyState:
	return null
	
## what happens during the physics process in this state
func physics(_delta : float) -> EnemyState:
	return null
