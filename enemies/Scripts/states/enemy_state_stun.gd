class_name EnemyStateStun extends EnemyState

@export var anim_name : String = "stun"
@export var knockback_speed: float = 200.0
@export var decelerate_speed: float = 10.0

@export_category("AI")
@export var next_state : EnemyState


var _animation_finished : bool = false
var _damage_position : Vector2
var _direction : Vector2

func _ready():
	pass
	
## What happens when you initalize this state
func init() -> void:
	enemy.enemy_damaged.connect( _on_enemy_damaged )
	pass
	
## what happens when the player enters this state
func enter() -> void:
	enemy.invunerable = true
	_animation_finished = false

	_direction = enemy.global_position.direction_to( _damage_position )
	enemy.setDirection(_direction)
	enemy.velocity = _direction * -knockback_speed
	
	enemy.updateAnimation(anim_name)
	enemy.animation_player.animation_finished.connect( _on_animation_finished )
	pass
	
## what happens when the player exits this state
func exit() -> void:
	enemy.invunerable = false
	enemy.animation_player.animation_finished.disconnect( _on_animation_finished )
	pass
	
## what happens during the process in this state
func process(_delta):
	if _animation_finished == true:
		return next_state
	enemy.velocity -= enemy.velocity * decelerate_speed * _delta
	return null
	
## what happens during the physics process in this state
func physics(_delta : float) -> EnemyState:
	return null

func _on_enemy_damaged(hurtBox : HurtBox) -> void:
	_damage_position = hurtBox.global_position
	state_machine.changeState( self )
	
func _on_animation_finished( _a : String) -> void:
	_animation_finished = true
