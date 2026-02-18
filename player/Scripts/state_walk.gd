class_name State_walk extends State

# base movement speed -- skills add on top of this via PlayerStats.speed_bonus
@export var moveSpeed: float = 115.0

@onready var attack: State = $"../attack"
@onready var idle: State = $"../idle"


func enter() -> void:
	player.updateAnimation("walk")


func exit() -> void:
	pass


func process(_delta: float) -> State:
	if player.direction == Vector2.ZERO:
		return idle

	# add the skill bonus on top of base speed
	player.velocity = player.direction * (moveSpeed + PlayerStats.speed_bonus)

	if player.setDirection():
		player.updateAnimation("walk")
	return null


func physics(_delta: float) -> State:
	return null


func handleInput(_event: InputEvent) -> State:
	if _event.is_action_pressed("Attack"):
		return attack
	return null
