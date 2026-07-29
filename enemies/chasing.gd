class_name EnemyStateChasing extends EnemyState

@export var anim_name : String = "Attack"
@export var attack_speed: float = 20.0
@export var turn_rate : float = 0.25

@export_category("AI")
@export var state_agro_duration : float = 1.0
@export var myvision : vision
@export var attack_target_area : HurtBox
@export var next_state : EnemyState


var _timer : float = 0.0
var _direction : Vector2
var see_target : bool = false
var target: Node2D
var visible_targets: Array[Node2D] = []

func _ready():
	
	
	pass
	
## What happens when you initalize this state
func init() -> void:
	if myvision:
		myvision.target_arrived.connect(_on_target_entered)
		myvision.target_left.connect(_on_target_exited)
	
## what happens when the player enters this state
func enter() -> void:
	_timer = state_agro_duration
	_select_target()
	enemy.updateAnimation(anim_name)
	if attack_target_area:
		attack_target_area.monitoring = true
	
## what happens when the player exits this state
func exit() -> void:
	if attack_target_area:
		attack_target_area.monitoring = false
	see_target = false
	
## what happens during the process in this state
func process(_delta):
	if not is_instance_valid(target):
		_select_target()
	if target != null:
		var new_dir: Vector2 = enemy.global_position.direction_to(target.global_position)
		_direction = lerp(_direction, new_dir, turn_rate)
		enemy.velocity = _direction * attack_speed
		if enemy.setDirection(_direction):
			enemy.updateAnimation(anim_name)
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
