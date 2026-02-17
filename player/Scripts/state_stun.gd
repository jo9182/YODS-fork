class_name State_Stun extends State


@export var knockback_speed: float = 200.0
@export var decelerate_speed: float = 10.0
@export var invulnurable_duration : float = 1.0

var hurtBox : HurtBox
var direction : Vector2

var next_state : State = null

@onready var idle: State = $"../idle"

func init() -> void:
	player.player_damaged.connect( _player_damaged )

## what happens when the player enters this state
func enter() -> void:
	player.animation_player.animation_finished.connect( _animation_finished )
	
	direction = player.global_position.direction_to(hurtBox.global_position)
	player.velocity = direction * -knockback_speed
	player.setDirection()
	player.updateAnimation("stun")
	player.make_invulnarable( invulnurable_duration )
	player.effect_animation_player.play("damaged")
	pass
	
## what happens when the player exits this state
func exit() -> void:
	next_state = null
	player.animation_player.animation_finished.disconnect( _animation_finished )
	pass
	
## what happens during the process in this state
func process( _delta : float) -> State:
	player.velocity -= decelerate_speed * player.velocity * _delta
	return next_state
	
## what happens during the physics process in this state
func physics(_delta : float) -> State:
	return null

## what happens with input events in this state
func handleInput(_event : InputEvent) -> State:
	return null

func _player_damaged( _hurtBox : HurtBox) -> void:
	hurtBox = _hurtBox
	state_machine.changeState(self)

func _animation_finished(_a : String) -> void:
	next_state = idle

	
