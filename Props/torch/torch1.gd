class_name Torch1 extends Node2D

const PICKUP := preload("res://items/item_pickup/item_pickup.tscn")
const TORCH_ITEM_PATH := "res://items/torch.tres"

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: HitBox = $Hitbox

var broken := false
var placed_by_player := false
var placement_id := -1


func configure_as_placed(new_placement_id: int) -> void:
	placed_by_player = true
	placement_id = new_placement_id


func _ready() -> void:
	_activate()


func _activate() -> void:
	animation_player.play("Burn")
	hitbox.Damaged.connect(TakeDamage)


func TakeDamage(_hurt_box: HurtBox) -> void:
	if broken:
		return
	broken = true
	call_deferred("_break")


func _break() -> void:
	var torch_manager := get_node_or_null("/root/TorchManager")
	if torch_manager != null:
		torch_manager.record_torch_broken(self)
	var pickup := PICKUP.instantiate()
	get_parent().add_child(pickup)
	pickup.global_position = global_position
	pickup.item_data = load(TORCH_ITEM_PATH) as ItemData
	queue_free()
