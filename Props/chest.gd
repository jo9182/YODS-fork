class_name chest extends Node2D

@export_file("*.tscn") var lava
@export var chestName = "chestName"
@export var loot_table: LootTable
@export var replenishes_with_renown := true

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var marker_2d: Marker2D = $Marker2D
@onready var marker_2d_2: Marker2D = $Marker2D2
@onready var marker_2d_3: Marker2D = $Marker2D3
@onready var marker_2d_4: Marker2D = $Marker2D4
@onready var hurt_box: HurtBox = $HurtBox
@onready var mypersistence: persistence = $Persistence

const PICKUP = preload("res://items/item_pickup/item_pickup.tscn")

const SPREAD_RADIUS = 18.0
const ARC_HEIGHT = 20.0
const POP_DURATION = 0.35

var opened: bool = false


func _ready():
	mypersistence.data_loaded.connect(_set_chest_state)
	_set_chest_state()
	pass

func _set_chest_state() -> void:
	opened = mypersistence.value
	if opened:
		animation_player.play("Opened")
	else:
		animation_player.play("Closed")
	pass
	
func _unhandled_input(event: InputEvent) -> void:
	var in_range = (
		PlayerManager.player.global_position.x > marker_2d_2.global_position.x and
		PlayerManager.player.global_position.y > marker_2d.global_position.y and
		PlayerManager.player.global_position.y < marker_2d_3.global_position.y and
		PlayerManager.player.global_position.x < marker_2d_4.global_position.x
	)

	if in_range and event.is_action_pressed("interact"):
		if opened:
			return
		opened = true
		mypersistence.setValue()
		_register_renown_chest()
		animation_player.play("Open")
		await get_tree().create_timer(0.2).timeout
		_spawn_loot()


func _register_renown_chest() -> void:
	var renown := get_node_or_null("/root/DungeonRenown")
	if renown != null:
		renown.call("register_opened_chest", mypersistence.get_persistence_key(), replenishes_with_renown)


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

		# spread items in a downward-facing semicircle so nothing lands
		# under or behind the chest where it can't be picked up.
		# angle goes from 0 (right) through PI (left), passing through
		# PI/2 (straight down toward the player) at the midpoint.
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
