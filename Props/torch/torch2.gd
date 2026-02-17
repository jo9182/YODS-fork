class_name Torch2 extends Node2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready():
	animation_player.play("hanging")
	pass


func TakeDamage( hurtBox : HurtBox) -> void:
	queue_free()
	pass
