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
@export var patrol_radius := Vector2(96.0, 64.0)
@export var persistence_id := ""
@export var patrol_route_path: NodePath

var cardinalDirection: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO
var player: Player
var invunerable: bool = false
var is_dead: bool = false
var patrol_anchor := Vector2.ZERO
var navigation_target := Vector2.INF
var navigation_path := PackedVector2Array()
var navigation_index := 0
var navigation_refresh_time := 0.0
var persistence_room_key := ""
var patrol_route: PatrolRoute
var patrol_route_id := ""
var patrol_waypoint_index := 0
var patrol_route_direction := 1
var patrol_wait_remaining := 0.0
var patrol_route_finished := false
var patrol_configured := false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: HitBox = $Hitbox
@onready var state_machine: EnemyStateMachine = $EnemyStateMachine


func _ready():
	add_to_group("enemies")
	if not patrol_configured:
		patrol_anchor = global_position
	if not patrol_route_path.is_empty():
		patrol_route = get_node_or_null(patrol_route_path) as PatrolRoute
		if patrol_route != null:
			patrol_route_id = patrol_route.route_id
	state_machine.initalize(self)
	player = PlayerManager.player
	hitbox.Damaged.connect(_take_damage)


func _process(_delta):
	pass


func _physics_process(_delta):
	navigation_refresh_time = maxf(navigation_refresh_time - _delta, 0.0)
	move_and_slide()
	if is_on_wall():
		clear_navigation()


func configure_patrol(anchor: Vector2, radius: Vector2 = Vector2(-1.0, -1.0)) -> void:
	patrol_anchor = anchor
	patrol_configured = true
	if radius.x >= 0.0 and radius.y >= 0.0:
		patrol_radius = radius
	clear_navigation()


func configure_patrol_route(route: PatrolRoute, route_id := "") -> void:
	patrol_route = route
	patrol_route_id = route_id if not route_id.is_empty() else route.route_id if route != null else ""
	patrol_waypoint_index = 0
	patrol_route_direction = 1
	patrol_wait_remaining = 0.0
	patrol_route_finished = false
	patrol_configured = true
	clear_navigation()


func has_patrol_route() -> bool:
	return patrol_route != null and not patrol_route.get_waypoints().is_empty()


func get_patrol_target() -> Vector2:
	if not has_patrol_route():
		return patrol_anchor
	return patrol_route.get_waypoint_position(patrol_waypoint_index)


func get_patrol_wait() -> float:
	if not has_patrol_route():
		return 0.0
	return patrol_route.get_waypoint_wait(patrol_waypoint_index)


func advance_patrol_waypoint() -> bool:
	if not has_patrol_route() or patrol_route_finished:
		return false
	var next := patrol_route.get_next_index(patrol_waypoint_index, patrol_route_direction)
	patrol_waypoint_index = int(next.get("index", patrol_waypoint_index))
	patrol_route_direction = int(next.get("direction", patrol_route_direction))
	patrol_route_finished = bool(next.get("finished", false))
	patrol_wait_remaining = 0.0
	clear_navigation()
	return not patrol_route_finished


func move_toward_target(target_position: Vector2, move_speed: float) -> bool:
	if navigation_refresh_time <= 0.0 or navigation_target.distance_to(target_position) > 12.0:
		navigation_target = target_position
		navigation_path = DungeonPathfinder.get_point_path(global_position, target_position)
		navigation_index = 1
		navigation_refresh_time = 0.35

	while navigation_index < navigation_path.size() and global_position.distance_to(navigation_path[navigation_index]) <= 6.0:
		navigation_index += 1
	if navigation_index >= navigation_path.size():
		velocity = Vector2.ZERO
		return false

	var next_position := navigation_path[navigation_index]
	var offset := next_position - global_position
	if offset.length_squared() <= 0.001:
		velocity = Vector2.ZERO
		return false
	setDirection(offset)
	velocity = offset.normalized() * move_speed
	return true


func clear_navigation() -> void:
	navigation_target = Vector2.INF
	navigation_path = PackedVector2Array()
	navigation_index = 0
	navigation_refresh_time = 0.0


func get_persistence_state() -> Dictionary:
	return {
		"position_x": global_position.x,
		"position_y": global_position.y,
		"hp": hp,
		"direction_x": cardinalDirection.x,
		"direction_y": cardinalDirection.y,
		"patrol_anchor_x": patrol_anchor.x,
		"patrol_anchor_y": patrol_anchor.y,
		"patrol_route_id": patrol_route_id,
		"patrol_waypoint_index": patrol_waypoint_index,
		"patrol_route_direction": patrol_route_direction,
		"patrol_wait_remaining": patrol_wait_remaining,
		"patrol_route_finished": patrol_route_finished,
	}


func restore_persistence_state(state: Dictionary) -> void:
	global_position = Vector2(float(state.get("position_x", global_position.x)), float(state.get("position_y", global_position.y)))
	hp = int(state.get("hp", hp))
	patrol_anchor = Vector2(float(state.get("patrol_anchor_x", patrol_anchor.x)), float(state.get("patrol_anchor_y", patrol_anchor.y)))
	patrol_waypoint_index = int(state.get("patrol_waypoint_index", patrol_waypoint_index))
	patrol_route_direction = int(state.get("patrol_route_direction", patrol_route_direction))
	patrol_wait_remaining = maxf(float(state.get("patrol_wait_remaining", patrol_wait_remaining)), 0.0)
	patrol_route_finished = bool(state.get("patrol_route_finished", patrol_route_finished))
	patrol_configured = true
	cardinalDirection = Vector2(float(state.get("direction_x", cardinalDirection.x)), float(state.get("direction_y", cardinalDirection.y)))
	if cardinalDirection == Vector2.ZERO:
		cardinalDirection = Vector2.DOWN
	sprite.scale.x = -1 if cardinalDirection == Vector2.LEFT else 1
	velocity = Vector2.ZERO
	clear_navigation()


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
	direction = _NewDirection
	if direction == Vector2.ZERO:
		return false
	var directionID: int = int(round(
		(direction + cardinalDirection * 0.1).angle() 
		/ TAU * DIR_4.size()
	))
	
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
		is_dead = true
		enemy_destroyed.emit(hurtBox)
