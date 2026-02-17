class_name Coin extends Node2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready():
	animation_player.play("Spin")
	$Hitbox.Damaged.connect( TakeDamage )
	pass


func TakeDamage( _hurtBox : HurtBox) -> void:
	queue_free()
	pass
