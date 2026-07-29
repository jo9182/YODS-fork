@tool
class_name item_pickup extends Node2D

@export var item_data: ItemData : set = _set_item_data

@onready var area_2d: Area2D = $Area2D
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	_update_texture()
	if Engine.is_editor_hint():
		return
	add_to_group("item_pickups")
	area_2d.body_entered.connect(_on_body_entered)


func _on_body_entered(b) -> void:
	if b is Player:
		if item_data:
			if item_data.use_on_pickup:
				# item handles its own effect (e.g. coin adds gold), never enters inventory
				item_data.use()
				item_picked_up()
			elif PlayerManager.INVENTORY_DATA.addItem(item_data) == true:
				if item_data is TorchItemData:
					SaveManager.save_game()
				item_picked_up()


func item_picked_up() -> void:
	area_2d.body_entered.disconnect(_on_body_entered)
	audio_stream_player_2d.play()
	visible = false
	await audio_stream_player_2d.finished
	queue_free()


func collect_for_dungeon_explorer() -> bool:
	return take_for_dungeon_explorer() != null


func take_for_dungeon_explorer() -> ItemData:
	if item_data == null or item_data.use_on_pickup:
		return null
	var collected_item := item_data
	area_2d.set_deferred("monitoring", false)
	visible = false
	queue_free()
	return collected_item


func _set_item_data(value: ItemData) -> void:
	item_data = value
	_update_texture()


func _update_texture() -> void:
	if item_data and sprite_2d:
		sprite_2d.texture = item_data.texture
