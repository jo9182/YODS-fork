class_name  Player extends CharacterBody2D

signal DirectionChanged( NewDirection : Vector2 )
signal player_damaged(hurtbox : HurtBox)
## a variable that has two features (x,y) and in this instance DOWN means (0,-1)
var cardinalDirection : Vector2 = Vector2.DOWN
## a variable that has two features (x,y) and in this instance ZERO means (0,0)

const DIR_4 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP ]
const TORCH_ITEM_PATH := "res://items/torch.tres"
const LANTERN_BASE_ENERGY := 0.3
const LANTERN_BASE_SCALE := 0.55
const LANTERN_TORCH_ENERGY := 0.13
const LANTERN_TORCH_SCALE := 0.13
var direction : Vector2 = Vector2.ZERO
## on ready variable only exsist when the node is in the scene tree and will only call on it if it exsist
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var hitbox: HitBox = $Sprite2D/Hitbox

@onready var lantern_light: PointLight2D = $LanternLight

@onready var effect_animation_player: AnimationPlayer = $EffectAnimationPlayer

var invulnarable : bool = false
var hp : int = 10
var max_hp : int = 10

func _ready():
	PlayerManager.player = self
	state_machine.initalize(self)
	hitbox.Damaged.connect( _take_damage )
	update_hp(99)
	_update_lantern_light()
	pass

func _process(_delta):
	## gets how strong the direction is to the right by subtracting the left and the right so it is either 1,-1, or 0
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	## gets how strong the direction is to the right by subtracting the up and the down so it is either 1,-1, or 0
	direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	
	## prevents the total magnitude of the vector from being greater than one
	## When moving sideways you won't move faster
	direction = direction.normalized()
	_update_lantern_light()
	
	
## causes movement
func _physics_process(_delta):
	move_and_slide()

## boolean method
func setDirection() -> bool:
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
	##
	DirectionChanged.emit(newDirection)
	sprite.scale.x = -1 if cardinalDirection == Vector2.LEFT else 1
	return true
	

	
	## void method
func updateAnimation(state : String) -> void:
	## calls the onready variable to use a feature of godot AnimationPlayer nodes called play that
	## allows you to play an animation and it chooses the correct animation by determing the state and the direction
	animation_player.play(state + "_" + animDirection())
	pass
	
	## String method
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

func _take_damage( hurtBox : HurtBox) -> void:
	if invulnarable == true:
		return
	update_hp( -hurtBox.damage)
	if hp > 0:
		player_damaged.emit(hurtBox)
	else:
		animation_player.play("death")
		invulnarable = true
		await get_tree().create_timer(.54).timeout
		if SaveManager.get_save_file() != null:
			SaveManager.load_game()
			invulnarable = false
		else:
			update_hp(max_hp)
			SaveManager.save_game()
			SaveManager.load_game()
			invulnarable = false
	pass
	
func update_hp( delta : int) -> void:
	hp = clampi(hp+delta,0,max_hp)
	PlayerHud.update_hp(hp,max_hp)
	pass
	
func make_invulnarable( _duration : float = 1.0) -> void:
	invulnarable = true
	hitbox.monitoring = false
	
	await get_tree().create_timer( _duration ).timeout
	
	invulnarable = false
	hitbox.monitoring = true
	pass


func _update_lantern_light() -> void:
	var torch_count := 0
	for slot in PlayerManager.INVENTORY_DATA.slots:
		if slot != null and slot.item_data != null and slot.item_data.resource_path == TORCH_ITEM_PATH:
			torch_count += slot.quantity
	var light_level := clampi(torch_count, 0, 5)
	lantern_light.energy = LANTERN_BASE_ENERGY + light_level * LANTERN_TORCH_ENERGY + PlayerStats.lantern_energy_bonus
	lantern_light.texture_scale = LANTERN_BASE_SCALE + light_level * LANTERN_TORCH_SCALE + PlayerStats.lantern_scale_bonus


func refresh_lantern() -> void:
	_update_lantern_light()
