class_name Enemy extends CharacterBody2D

signal DirectionChanged( NewDirection : Vector2 )
signal enemy_damaged( hurtBox : HurtBox )
signal enemy_destroyed( hurtBox : HurtBox )
const DIR_4 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP ]
@export var hp : int = 3
var direction : Vector2 = Vector2.ZERO
var cardinalDirection : Vector2 = Vector2.DOWN
var player : Player
var invunerable : bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: HitBox = $Hitbox
@onready var state_machine : EnemyStateMachine = $EnemyStateMachine





func _ready():
	state_machine.initalize( self )
	player = PlayerManager.player
	hitbox.Damaged.connect( _take_damage )
	pass
	
func _process(_delta):
	pass
	
	
func _physics_process(_delta):
	move_and_slide()

func setDirection( _NewDirection : Vector2) -> bool:
	## if you haven't moved yet don't update
	if direction == Vector2.ZERO:
		return false
	# Creates a variable that is an int that int is rounded so that it is an int it calls 
	#the direction variable angle and divides it to ensure that it can only be one of the 4 directions in the variableDIR_4
	#The cardinal direction is addedto skew the direction and keep the player facing one direction when moving diagonal
	var directionID : int = int(round((direction + cardinalDirection * 0.1).angle() / TAU * DIR_4.size()))
	
	#
	var newDirection = DIR_4[directionID]
	
	## if you did move and you moved horizontally which way did you go
	## this is found through the Vector2 (x,y) by determing if the x is negative

	## if you keep moving in the same direction then you do not update
	if newDirection == cardinalDirection:
		return false
	
	## otherwise change your cardinalDirection to the newDirection and update animation
	cardinalDirection = newDirection
	DirectionChanged.emit(newDirection)
	sprite.scale.x = -1 if cardinalDirection == Vector2.LEFT else 1
	return true
	
func updateAnimation(state : String) -> void:
	## calls the onready variable to use a feature of godot AnimationPlayer nodes called play that
	## allows you to play an animation and it chooses the correct animation by determing the state and the direction
	animation_player.play(state + "_" + animDirection())
	pass
	
func animDirection() -> String:
	## if (0,-1) return "down"
	if cardinalDirection == Vector2.DOWN:
		return "down"
	## if (0,1) return "up"
	elif cardinalDirection == Vector2.UP:
		return "up"
	## otherwise return side
	else :
		return "side"


func _take_damage( hurtBox : HurtBox ) -> void:
	if invunerable == true:
		return
	hp -= hurtBox.damage
	if hp > 0:
		enemy_damaged.emit( hurtBox )
	else:
		enemy_destroyed.emit(hurtBox)
	pass
