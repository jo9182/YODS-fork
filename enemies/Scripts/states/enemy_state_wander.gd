class_name EnemyStateWander extends EnemyState

@export var anim_name : String = "walk"
@export var wander_speed: float = 20.0

@export_category("AI")
@export var state_animation_duration : float = 0.5
@export var state_cycles_min : int = 1 
@export var state_cycles_max : int = 3
@export var next_state : EnemyState


var _timer : float = 0.0
var _direction : Vector2
var _patrol_target := Vector2.ZERO
var _waiting_at_waypoint := false

func _ready():
	pass
	
## What happens when you initalize this state
func init() -> void:
	pass
	
## what happens when the player enters this state
func enter() -> void:
	_waiting_at_waypoint = false
	if enemy.has_patrol_route():
		_patrol_target = enemy.get_patrol_target()
		_timer = enemy.patrol_wait_remaining
		_waiting_at_waypoint = enemy.patrol_wait_remaining > 0.0
	else:
		_timer = randi_range(state_cycles_min, state_cycles_max) * state_animation_duration
		_patrol_target = DungeonPathfinder.get_wander_point(enemy.patrol_anchor, enemy.patrol_radius)
	enemy.clear_navigation()
	enemy.velocity = Vector2.ZERO
	enemy.updateAnimation("idle" if _waiting_at_waypoint else anim_name)
	pass
	
## what happens when the player exits this state
func exit() -> void:
	pass
	
## what happens during the process in this state
func process(_delta):
	if enemy.has_patrol_route():
		if enemy.patrol_route_finished:
			enemy.velocity = Vector2.ZERO
			enemy.updateAnimation("idle")
			return null
		if _waiting_at_waypoint:
			_timer = maxf(_timer - _delta, 0.0)
			enemy.patrol_wait_remaining = _timer
			enemy.velocity = Vector2.ZERO
			enemy.updateAnimation("idle")
			if _timer <= 0.0:
				if not enemy.advance_patrol_waypoint():
					return null
				_patrol_target = enemy.get_patrol_target()
				_waiting_at_waypoint = false
				enemy.updateAnimation(anim_name)
			return null
		if enemy.global_position.distance_to(_patrol_target) <= 8.0:
			enemy.velocity = Vector2.ZERO
			_timer = enemy.get_patrol_wait()
			enemy.patrol_wait_remaining = _timer
			_waiting_at_waypoint = _timer > 0.0
			if _waiting_at_waypoint:
				enemy.updateAnimation("idle")
			else:
				if not enemy.advance_patrol_waypoint():
					return null
				_patrol_target = enemy.get_patrol_target()
			return null
		if not enemy.move_toward_target(_patrol_target, wander_speed):
			if not enemy.advance_patrol_waypoint():
				return null
			_patrol_target = enemy.get_patrol_target()
		return null
	_timer -= _delta
	if _timer <= 0:
		return next_state
	if enemy.global_position.distance_to(_patrol_target) <= 8.0:
		enemy.velocity = Vector2.ZERO
		return next_state
	if not enemy.move_toward_target(_patrol_target, wander_speed):
		_patrol_target = DungeonPathfinder.get_wander_point(enemy.patrol_anchor, enemy.patrol_radius)
		enemy.clear_navigation()
	return null
	
	
## what happens during the physics process in this state
func physics(_delta : float) -> EnemyState:
	return null
