class_name EnemyStateChasing extends EnemyState

@export var anim_name : String = "Attack"
@export var walk_anim_name : String = "walk"
@export var attack_speed: float = 20.0
@export var turn_rate : float = 0.25
@export var attack_range: float = 28.0
@export var attack_cooldown: float = 0.9
@export var attack_windup: float = 0.45
@export var attack_duration: float = 0.18

@export_category("AI")
@export var state_agro_duration : float = 1.0
@export var myvision : vision
@export var attack_target_area : HurtBox
@export var next_state : EnemyState


var _timer : float = 0.0
var _direction : Vector2
var _attack_cooldown_timer := 0.0
var _attack_elapsed := 0.0
var _attack_in_progress := false
var _attack_hitbox_enabled := false
var _animation_state := ""
var see_target : bool = false
var target: Node2D
var visible_targets: Array[Node2D] = []

func _ready():
	
	
	pass
	
## What happens when you initalize this state
func init() -> void:
	if attack_target_area:
		attack_target_area.monitoring = false
	if myvision:
		myvision.target_arrived.connect(_on_target_entered)
		myvision.target_left.connect(_on_target_exited)
	
## what happens when the player enters this state
func enter() -> void:
	_timer = state_agro_duration
	_attack_cooldown_timer = 0.0
	_attack_elapsed = 0.0
	_attack_in_progress = false
	_attack_hitbox_enabled = false
	_animation_state = ""
	_select_target()
	enemy.velocity = Vector2.ZERO
	enemy.clear_navigation()
	if attack_target_area:
		attack_target_area.set_deferred("monitoring", false)
	
## what happens when the player exits this state
func exit() -> void:
	if attack_target_area:
		attack_target_area.set_deferred("monitoring", false)
	_attack_in_progress = false
	_attack_hitbox_enabled = false
	see_target = false
	enemy.clear_navigation()
	
## what happens during the process in this state
func process(_delta):
	_attack_cooldown_timer = maxf(_attack_cooldown_timer - _delta, 0.0)
	_update_attack_window(_delta)
	if not is_instance_valid(target):
		_select_target()
	if target != null:
		var target_offset := target.global_position - enemy.global_position
		var target_distance := target_offset.length()
		if _attack_in_progress:
			enemy.velocity = Vector2.ZERO
		elif target_distance <= attack_range:
			enemy.velocity = Vector2.ZERO
			enemy.setDirection(target_offset)
			_play_animation("idle")
			if _attack_cooldown_timer <= 0.0:
				_start_attack()
		else:
			var new_direction: Vector2 = enemy.global_position.direction_to(target.global_position)
			_direction = _direction.lerp(new_direction, turn_rate)
			if enemy.move_toward_target(target.global_position, attack_speed):
				_play_animation(walk_anim_name)
			else:
				enemy.velocity = Vector2.ZERO
	else:
		enemy.velocity = Vector2.ZERO
	if not see_target:
		_timer -= _delta
		if _timer <= 0.0:
			return next_state
	else:
		_timer = state_agro_duration
	return null
	
	
## what happens during the physics process in this state
func physics(_delta : float) -> EnemyState:
	return null
	
func _on_target_entered(new_target: Node2D) -> void:
	if not visible_targets.has(new_target):
		visible_targets.append(new_target)
	_select_target()
	if (
		state_machine.currentState is EnemyStateStun
		or state_machine.currentState is EnemyStateDestroy
		):
		return
	state_machine.changeState(self)


func _on_target_exited(old_target: Node2D) -> void:
	visible_targets.erase(old_target)
	_select_target()
	if target == null:
		_timer = state_agro_duration


func _select_target() -> void:
	target = null
	var nearest_distance := INF
	for candidate in visible_targets:
		if not is_instance_valid(candidate) or candidate.is_queued_for_deletion():
			continue
		var distance := enemy.global_position.distance_to(candidate.global_position)
		if distance < nearest_distance:
			target = candidate
			nearest_distance = distance
	see_target = target != null


func _start_attack() -> void:
	_attack_cooldown_timer = attack_cooldown
	_attack_elapsed = 0.0
	_attack_in_progress = true
	_attack_hitbox_enabled = false
	enemy.velocity = Vector2.ZERO
	_play_animation(anim_name)


func _update_attack_window(delta: float) -> void:
	if not _attack_in_progress:
		return
	_attack_elapsed += delta
	if not _attack_hitbox_enabled and _attack_elapsed >= attack_windup:
		_attack_hitbox_enabled = true
		if attack_target_area:
			attack_target_area.set_deferred("monitoring", true)
	if _attack_hitbox_enabled and _attack_elapsed >= attack_windup + attack_duration:
		_attack_hitbox_enabled = false
		_attack_in_progress = false
		if attack_target_area:
			attack_target_area.set_deferred("monitoring", false)


func _play_animation(animation_name: String) -> void:
	if animation_name.is_empty() or _animation_state == animation_name:
		return
	_animation_state = animation_name
	enemy.updateAnimation(animation_name)
