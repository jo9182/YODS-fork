class_name State_walk extends State

@export var moveSpeed: float = 115.0

@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
@onready var attack: State = $"../attack"
@onready var idle: State = $"../idle"
@onready var ranged: State = $"../ranged"


func enter() -> void:
	# play once, walk_side loops so it keeps going until another state exits
	animation_player.play("walk_side")


func exit() -> void:
	pass


func process(_delta: float) -> State:
	if player.direction == Vector2.ZERO:
		return idle

	player.velocity = player.direction * (moveSpeed + PlayerStats.speed_bonus)

	# keep cardinalDirection updated for attacks/ranged, but never touch the animation
	player.setDirection()

	return null


func physics(_delta: float) -> State:
	return null


func handleInput(_event: InputEvent) -> State:
	if _event.is_action_pressed("Attack"):
		return attack
	if _event.is_action_pressed("ranged"):
		return ranged
	return null
