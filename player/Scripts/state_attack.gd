class_name State_Attack extends State

@export var attack_sound : AudioStream
@export_range(1,20,0.5) var decelerateSpeed : float = 5.0

@onready var hurt_box: HurtBox = %AttackHurtBox
@onready var walk: State = $"../walk"
@onready var idle: State = $"../idle"
@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
@onready var attack_Anim: AnimationPlayer = $"../../Sprite2D/AttackEffectSprite/AnimationPlayer"
@onready var audio: AudioStreamPlayer2D = $"../../Audio/AudioStreamPlayer2D"
var attacking : bool = false

## what happens when the player enters this state
func enter() -> void:
	player.updateAnimation("attack")
	attack_Anim.play("attack_" + player.animDirection())
	animation_player.animation_finished.connect(endAttack)
	
	audio.stream = attack_sound
	audio.pitch_scale = randf_range(0.9,1.1)
	audio.play()
	attacking = true
	
	await get_tree().create_timer(0.075).timeout
	hurt_box.monitoring = true
	pass
	
## what happens when the player exits this state
func exit() -> void:
	animation_player.animation_finished.disconnect(endAttack)
	attacking = false
	hurt_box.monitoring = false
	pass
	
## what happens during the process in this state
func process( _delta : float) -> State:
	player.velocity -= player.velocity * decelerateSpeed * _delta
	
	if attacking == false:
		if player.direction == Vector2.ZERO:
			return idle
		else:
			return walk
	return null
	
## what happens during the physics process in this state
func physics(_delta : float) -> State:
	return null

## what happens with input events in this state
func handleInput(_event : InputEvent) -> State:
	return null
	
	
func endAttack( _newAnimName : String ) -> void:
	attacking = false
