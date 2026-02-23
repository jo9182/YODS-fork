
class_name State_Ranged extends State

const STONE: ItemData = preload("res://items/stone.tres")


@export var projectile_scene: PackedScene

@export var base_damage: int = 1
@export var fire_cooldown: float = 0.35

@onready var idle: State = $"../idle"
@onready var walk: State = $"../walk"

var _inventory: inventoryData = PlayerManager.INVENTORY_DATA
var _firing: bool = false


func enter() -> void:
	var stone_slot = _find_stone_slot()

	if stone_slot == null:
		print("[Ranged] no stones in inventory")
		_firing = false
		_go_to_idle_or_walk()
		return

	if projectile_scene == null:
		push_warning("[Ranged] projectile_scene not assigned in inspector")
		_firing = false
		_go_to_idle_or_walk()
		return

	_firing = true
	stone_slot.quantity -= 1
	print("[Ranged] consumed stone, remaining: ", stone_slot.quantity)
	_spawn_projectile()
	player.updateAnimation("attack")

	await get_tree().create_timer(fire_cooldown).timeout
	_firing = false


func exit() -> void:
	_firing = false


func process(_delta: float) -> State:
	if not _firing:
		return _go_to_idle_or_walk()
	return null


func physics(_delta: float) -> State:
	return null


func handleInput(_event: InputEvent) -> State:
	return null


func _find_stone_slot() -> slotData:
	for slot in _inventory.slots:
		if slot != null and slot.item_data == STONE and slot.quantity > 0:
			return slot
	return null


func _spawn_projectile() -> void:
	var proj = projectile_scene.instantiate()
	proj.direction = player.cardinalDirection
	proj.damage = base_damage + int(PlayerStats.damage_bonus)
	proj.global_position = player.global_position
	player.get_parent().add_child(proj)
	print("[Ranged] spawned at ", proj.global_position, " dir=", proj.direction, " damage=", proj.damage)


func _go_to_idle_or_walk() -> State:
	if player.direction == Vector2.ZERO:
		return idle
	return walk
