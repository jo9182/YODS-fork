@tool
class_name item_pickup extends Node2D

@export var item_data: ItemData : set = _set_item_data

# if this is set, picking up this item adds to gold instead of inventory
# drag coin.tres here on any coin pickup in the world
@export var coin_value: int = 1

@onready var area_2d: Area2D = $Area2D
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	_update_texture()
	if Engine.is_editor_hint():
		return
	area_2d.body_entered.connect(_on_body_entered)


func _on_body_entered(b) -> void:
	if b is Player:
		if item_data:
			# if coin_value is set, this pickup adds gold instead of an item
			if coin_value > 0:
				PlayerStats.add_gold(coin_value)
				item_picked_up()
			elif PlayerManager.INVENTORY_DATA.addItem(item_data) == true:
				item_picked_up()


func item_picked_up() -> void:
	area_2d.body_entered.disconnect(_on_body_entered)
	audio_stream_player_2d.play()
	visible = false
	await audio_stream_player_2d.finished
	queue_free()


func _set_item_data(value: ItemData) -> void:
	item_data = value
	_update_texture()


func _update_texture() -> void:
	if item_data and sprite_2d:
		sprite_2d.texture = item_data.texture
