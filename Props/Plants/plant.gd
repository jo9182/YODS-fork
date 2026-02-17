class_name Plant extends Node2D


func _ready():
	$Hitbox.Damaged.connect( TakeDamage )
	pass


func TakeDamage( hurtBox : HurtBox) -> void:
	queue_free()
	pass
