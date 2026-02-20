class_name EnemyStateChasing extends EnemyState

@export var anim_name : String = "Attack"
@export var attack_speed: float = 20.0
@export var turn_rate : float = 0.25

@export_category("AI")
@export var state_agro_duration : float = 0.5
@export var myvision : vision
@export var attack_target_area : HurtBox
@export var next_state : EnemyState


var _timer : float = 0.0
var _direction : Vector2
var see_player : bool = false

func _ready():
	pass
	
## What happens when you initalize this state
func init() -> void:
	if myvision:
		myvision.playerarrive.connect(_on_player_entered)
		myvision.playerarrive.connect(_on_player_exited)
	pass
	
## what happens when the player enters this state
func enter() -> void:
	_timer = state_agro_duration
	
	enemy.updateAnimation(anim_name)
	if myvision:
		myvision.monitoring = true
	pass
	
## what happens when the player exits this state
func exit() -> void:
	if myvision:
		myvision.monitoring = false
	see_player = false
	pass
	
## what happens during the process in this state
func process(_delta):
	var new_dir : Vector2 = enemy.global_position.direction_to(PlayerManager.player.global_position)
	_direction = lerp(_direction, new_dir,turn_rate)
	enemy.velocity = _direction * attack_speed
	if enemy.setDirection(_direction):
		enemy.updateAnimation(anim_name)
	
	if see_player == false:
		_timer -= _delta
		if _timer <= 0:
			return next_state
	else:
		_timer = state_agro_duration
	return null
	
	
## what happens during the physics process in this state
func physics(_delta : float) -> EnemyState:
	return null
	
func _on_player_entered() -> void:
	see_player = true
	if state_machine.currentState is EnemyStateStun:
		return
	state_machine.changeState(self)

func _on_player_exited() -> void:
	see_player = false
