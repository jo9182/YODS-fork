class_name Flag extends Node2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready():
	animation_player.play("Sway")
	pass


func TakeDamage( _hurtBox : HurtBox) -> void:
	queue_free()
	pass
