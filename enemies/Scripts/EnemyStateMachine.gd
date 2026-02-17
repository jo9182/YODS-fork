class_name EnemyStateMachine extends Node

var states : Array[EnemyState]

var prevState : EnemyState
var currentState : EnemyState

func _ready():
	process_mode = Node.PROCESS_MODE_DISABLED
	pass
	
func _process(delta):
	changeState( currentState.process( delta ) )
	pass
	
func _physics_process(delta):
	changeState( currentState.physics( delta ) )
	pass
	
func initalize( _enemy : Enemy) -> void:
	states = []
	
	for c in get_children():
		if c is EnemyState:
			states.append(c)
			
	for s in states:
		s.enemy = _enemy
		s.state_machine = self
		s.init()
		
		if states.size() > 0:
			changeState(states[0])
			process_mode = Node.PROCESS_MODE_INHERIT
	pass
		
	
func changeState( newState: EnemyState) -> void:
	if newState == null || newState==currentState:
		return
	if currentState:
		currentState.exit()
	
	prevState = currentState
	currentState = newState
	currentState.enter()
