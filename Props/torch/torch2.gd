class_name Torch2 extends Node2D

const PICKUP := preload("res://items/item_pickup/item_pickup.tscn")
const TORCH_ITEM_PATH := "res://items/torch.tres"

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: HitBox = $Hitbox

var broken := false


func _ready() -> void:
	animation_player.play("hanging")
	hitbox.Damaged.connect(TakeDamage)


func TakeDamage(_hurt_box: HurtBox) -> void:
	if broken:
		return
	broken = true
	call_deferred("_break")


func _break() -> void:
	var pickup := PICKUP.instantiate()
	get_parent().add_child(pickup)
	pickup.global_position = global_position
	pickup.item_data = load(TORCH_ITEM_PATH) as ItemData
	queue_free()
