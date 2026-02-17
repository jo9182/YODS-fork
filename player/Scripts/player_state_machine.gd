class_name  PlayerStateMachine extends Node

var states : Array[State]

var prevState : State
var currentState : State

func _ready():
	process_mode = Node.PROCESS_MODE_DISABLED
	pass
	
func _process(delta):
	changeState( currentState.process( delta ) )
	pass
	
func physics(delta):
	changeState( currentState.physics( delta ) )
	pass
	
	
func _unhandled_input(event):
	changeState(currentState.handleInput( event ))
	pass

func initalize( _player : Player) -> void:
	states = []
	
	for c in get_children():
		if c is State:
			states.append(c)
	
	if states.size() == 0:
		return
	states[0].player = _player
	states[0].state_machine = self
	
	for state in states:
		state.init()
	changeState(states[0])
	process_mode = Node.PROCESS_MODE_INHERIT

func changeState( newState: State) -> void:
	if newState == null || newState==currentState:
		return
	if currentState:
		currentState.exit()
	
	prevState = currentState
	currentState = newState
	currentState.enter()
