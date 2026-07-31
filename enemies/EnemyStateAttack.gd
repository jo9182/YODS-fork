class_name EnemyStateAttack extends EnemyState

@export var anim_name : String = "attack"
@export var damage : int = 2
@export var decelerate_speed: float = 10.0


@export_category("AI")


var _damage_position : Vector2
var _direction : Vector2

func _ready():
	pass
	
## What happens when you initalize this state
func init() -> void:
	pass
	
## what happens when the player enters this state
func enter() -> void:
	enemy.invunerable = true

	_direction = enemy.global_position.direction_to(_damage_position)
	enemy.setDirection(_direction)
	
	enemy.updateAnimation(anim_name)
	enemy.animation_player.animation_finished.connect( _on_animation_finished )
	pass
	
## what happens when the player exits this state
func exit() -> void:
	enemy.invunerable = false
	enemy.animation_player.animation_finished.disconnect( _on_animation_finished )
	pass
	
## what happens during the process in this state
func _process(_delta):
	enemy.velocity -= enemy.velocity * decelerate_speed * _delta
	pass
	
## what happens during the physics process in this state
func physics(_delta : float) -> EnemyState:
	return null

func _on_enemy_destroyed(hurtBox : HurtBox) -> void:
	_damage_position = hurtBox.global_position
	state_machine.changeState( self )
	
func _on_animation_finished( _a : String) -> void:
	enemy.queue_free()
