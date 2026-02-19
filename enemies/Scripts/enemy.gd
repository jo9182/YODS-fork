class_name Enemy extends CharacterBody2D

signal DirectionChanged(NewDirection: Vector2)
signal enemy_damaged(hurtBox: HurtBox)
signal enemy_destroyed(hurtBox: HurtBox)

const DIR_4 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
const PICKUP = preload("res://items/item_pickup/item_pickup.tscn")

const SPREAD_RADIUS = 16.0
const ARC_HEIGHT = 18.0
const POP_DURATION = 0.3

@export var hp: int = 3
@export var loot_table: LootTable

var direction: Vector2 = Vector2.ZERO
var cardinalDirection: Vector2 = Vector2.DOWN
var player: Player
var invunerable: bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: HitBox = $Hitbox
@onready var state_machine: EnemyStateMachine = $EnemyStateMachine


func _ready():
	state_machine.initalize(self)
	player = PlayerManager.player
	hitbox.Damaged.connect(_take_damage)


func _process(_delta):
	pass


func _physics_process(_delta):
	move_and_slide()


func drop_loot() -> void:
	if not loot_table:
		return

	var drops = loot_table.roll()
	var parent = get_parent()
	var spawn_pos = global_position
	var physical_drops: Array = []

	for drop in drops:
		if drop.has("gold"):
			PlayerStats.add_gold(drop["gold"])
		else:
			var item_data: ItemData = drop["item_data"]
			var quantity: int = drop["quantity"]
			for i in quantity:
				if item_data.use_on_pickup:
					item_data.use()
				else:
					var pickup = PICKUP.instantiate()
					pickup.item_data = item_data
					pickup.global_position = spawn_pos
					pickup.get_node("Area2D").monitoring = false
					pickup.get_node("Area2D").monitorable = false
					parent.add_child(pickup)
					physical_drops.append(pickup)

	_animate_drops(physical_drops)


func _animate_drops(drops: Array) -> void:
	if drops.is_empty():
		return

	var count = drops.size()
	for i in count:
		var pickup = drops[i]
		var angle = (PI / maxf(count - 1, 1)) * i if count > 1 else PI / 2.0
		var land_offset = Vector2(cos(angle), sin(angle)) * SPREAD_RADIUS
		var land_pos = pickup.global_position + land_offset

		var tween = pickup.create_tween()
		tween.set_parallel(true)

		tween.tween_property(pickup, "global_position:x", land_pos.x, POP_DURATION)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

		var peak_y = pickup.global_position.y + land_offset.y - ARC_HEIGHT
		tween.tween_property(pickup, "global_position:y", peak_y, POP_DURATION * 0.45)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.chain().tween_property(pickup, "global_position:y", land_pos.y, POP_DURATION * 0.55)\
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

		tween.chain().tween_callback(func():
			pickup.get_node("Area2D").monitoring = true
			pickup.get_node("Area2D").monitorable = true)


func setDirection(_NewDirection: Vector2) -> bool:
	if direction == Vector2.ZERO:
		return false
	var directionID: int = int(round((direction + cardinalDirection * 0.1).angle() / TAU * DIR_4.size()))
	var newDirection = DIR_4[directionID]
	if newDirection == cardinalDirection:
		return false
	cardinalDirection = newDirection
	DirectionChanged.emit(newDirection)
	sprite.scale.x = -1 if cardinalDirection == Vector2.LEFT else 1
	return true


func updateAnimation(state: String) -> void:
	animation_player.play(state + "_" + animDirection())


func animDirection() -> String:
	if cardinalDirection == Vector2.DOWN:
		return "down"
	elif cardinalDirection == Vector2.UP:
		return "up"
	else:
		return "side"


func _take_damage(hurtBox: HurtBox) -> void:
	if invunerable == true:
		return
	hp -= hurtBox.damage
	if hp > 0:
		enemy_damaged.emit(hurtBox)
	else:
		enemy_destroyed.emit(hurtBox)
