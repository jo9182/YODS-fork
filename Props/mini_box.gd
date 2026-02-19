class_name mini_box extends Node2D

@export var loot_table: LootTable

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var marker_2d: Marker2D = $Marker2D
@onready var marker_2d_2: Marker2D = $Marker2D2
@onready var marker_2d_3: Marker2D = $Marker2D3
@onready var marker_2d_4: Marker2D = $Marker2D4
@onready var hurt_box: HurtBox = $HurtBox

const PICKUP = preload("res://items/item_pickup/item_pickup.tscn")

const SPREAD_RADIUS = 14.0
const ARC_HEIGHT = 16.0
const POP_DURATION = 0.3

var opened: bool = false


func _ready():
	pass


func alreadyopened() -> void:
	animation_player.play("Open")


func _unhandled_input(event: InputEvent) -> void:
	var in_range = (
		PlayerManager.player.global_position.x > marker_2d_2.global_position.x and
		PlayerManager.player.global_position.y > marker_2d.global_position.y and
		PlayerManager.player.global_position.y < marker_2d_3.global_position.y and
		PlayerManager.player.global_position.x < marker_2d_4.global_position.x
	)

	if in_range and event.is_action_pressed("interact"):
		if opened:
			alreadyopened()
			return
		opened = true
		animation_player.play("Open")
		await get_tree().create_timer(0.15).timeout
		_spawn_loot()


func _spawn_loot() -> void:
	if not loot_table:
		return

	var drops = loot_table.roll()
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
					pickup.get_node("Area2D").monitoring = false
					pickup.get_node("Area2D").monitorable = false
					add_child(pickup)
					pickup.position = Vector2.ZERO
					physical_drops.append(pickup)

	_animate_drops(physical_drops)


func _animate_drops(drops: Array) -> void:
	if drops.is_empty():
		return

	var count = drops.size()
	for i in count:
		var pickup = drops[i]
		var angle = (PI / maxf(count - 1, 1)) * i if count > 1 else PI / 2.0
		var land_pos = Vector2(cos(angle), sin(angle)) * SPREAD_RADIUS

		var tween = create_tween()
		tween.set_parallel(true)

		tween.tween_property(pickup, "position:x", land_pos.x, POP_DURATION)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

		var peak_y = land_pos.y - ARC_HEIGHT
		tween.tween_property(pickup, "position:y", peak_y, POP_DURATION * 0.45)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.chain().tween_property(pickup, "position:y", land_pos.y, POP_DURATION * 0.55)\
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

		tween.chain().tween_callback(func():
			pickup.get_node("Area2D").monitoring = true
			pickup.get_node("Area2D").monitorable = true)
			
