class_name arrow_trap extends Node2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var area_2d: Area2D = $Area2D
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var marker_2d: Marker2D = $Marker2D
@onready var marker_2d_2: Marker2D = $Marker2D2
@onready var marker_2d_3: Marker2D = $Marker2D3
@onready var marker_2d_4: Marker2D = $Marker2D4
@onready var hurt_box: HurtBox = $HurtBox


func _ready():
	pass




func _on_area_2d_body_entered(_body: Node2D) -> void:
	await get_tree().create_timer(.3).timeout
	animation_player.play("Shoot")
	if PlayerManager.player.global_position.x > marker_2d_2.global_position.x and PlayerManager.player.global_position.y > marker_2d.global_position.y and PlayerManager.player.global_position.y < marker_2d_3.global_position.y and PlayerManager.player.global_position.x < marker_2d_4.global_position.x:
		PlayerManager.player._take_damage(hurt_box)
	pass # Replace with function body.
