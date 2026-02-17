class_name mini_box extends Node2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var area_2d: Area2D = $Area2D
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var marker_2d: Marker2D = $Marker2D
@onready var marker_2d_2: Marker2D = $Marker2D2
@onready var marker_2d_3: Marker2D = $Marker2D3
@onready var marker_2d_4: Marker2D = $Marker2D4
@onready var hurt_box: HurtBox = $HurtBox
const PICKUP = preload("res://items/item_pickup/item_pickup.tscn")
const DATA = preload("res://items/coin.tres")
var opened : bool = false

var COIN = Coin

func _ready():
	
	pass



func alreadyopened() -> void:
	animation_player.play("Open")
	pass
	
func _unhandled_input(event: InputEvent) -> void:
	if PlayerManager.player.global_position.x > marker_2d_2.global_position.x and PlayerManager.player.global_position.y > marker_2d.global_position.y and PlayerManager.player.global_position.y < marker_2d_3.global_position.y and PlayerManager.player.global_position.x < marker_2d_4.global_position.x:
		if event.is_action_pressed("interact"):
			if opened == false:
				animation_player.play("Open")
				var coin = preload("res://items/item_pickup/item_pickup.tscn").instantiate()
				coin.item_data = DATA
				add_child(coin)
				coin.position = Vector2(0,40)
				opened = true
			else:
				alreadyopened()
