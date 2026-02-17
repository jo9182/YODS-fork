class_name HitBox extends Area2D

signal Damaged( hurtBox : HurtBox)

func _ready():
	pass

func _process(_delta):
	pass

func TakeDamage( hurtBox : HurtBox) -> void:
	Damaged.emit( hurtBox )
	pass
