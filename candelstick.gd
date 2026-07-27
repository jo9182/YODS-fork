class_name candlestick extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready():
	animation_player.play("Burn")
	pass


func TakeDamage( hurtBox : HurtBox) -> void:
	queue_free()
	pass
