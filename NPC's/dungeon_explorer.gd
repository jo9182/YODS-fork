class_name DungeonExplorer extends CharacterBody2D

const DIRECTION_FRAMES := {
	"down": 0,
	"left": 48,
	"right": 48,
	"up": 72,
}
const EXPLORER_NAMES := ["Arlen", "Brea", "Cato", "Dara", "Eris", "Fenn", "Gale", "Hollis"]
const ATTACK_FRAME_OFFSETS := [12, 13, 14, 15]
const ATTACK_OFFSETS := {
	"down": Vector2(0, 11),
	"left": Vector2(-12, -5),
	"right": Vector2(12, -5),
	"up": Vector2(0, -18),
}
const ATTACK_ANIMATION_DURATION := 0.32
const PARTY_FOLLOW_DISTANCE := 30.0
const PICKUP_SCENE := preload("res://items/item_pickup/item_pickup.tscn")
const FLOOR_GEAR := {
	1: [preload("res://items/stone.tres")],
	2: [preload("res://items/stone.tres"), preload("res://items/potion.tres")],
	3: [preload("res://items/potion.tres"), preload("res://items/gem.tres")],
	4: [preload("res://items/gem.tres"), preload("res://items/vamp_tooth.tres"), preload("res://items/torch.tres")],
}

@export var move_speed := 30.0
@export var aggro_range := 150.0
@export var attack_range := 26.0
@export var pickup_range := 14.0
@export var attack_cooldown := 0.9
@export var max_health := 5

var anchor_position := Vector2.ZERO
var wander_target := Vector2.ZERO
var wander_time := 0.0
var attack_time := 0.0
var walk_time := 0.0
var attack_animation_time := 0.0
var path_refresh_time := 0.0
var facing := "down"
var collected_items := 0
var current_health := 5
var current_floor := 1
var navigation_target := Vector2.INF
var navigation_path := PackedVector2Array()
var navigation_index := 0
var is_dead := false
var carried_items: Array[ItemData] = []
var explorer_name := ""
var party_title := ""
var party_role := ""
var party_leader: DungeonExplorer

@onready var sprite: Sprite2D = $Sprite2D
@onready var name_label: Label = $NameLabel
@onready var status_label: Label = $StatusLabel
@onready var attack_hurt_box: HurtBox = $AttackHurtBox
@onready var hitbox: HitBox = $Hitbox


func _ready() -> void:
	add_to_group("dungeon_explorers")
	anchor_position = global_position
	explorer_name = EXPLORER_NAMES.pick_random()
	name_label.text = explorer_name
	status_label.text = "Exploring"
	current_health = max_health
	attack_hurt_box.monitoring = false
	hitbox.Damaged.connect(_take_damage)
	_choose_wander_target()
	_update_sprite(Vector2.ZERO, 0.0)


func setup(spawn_position: Vector2, floor_number: int) -> void:
	global_position = spawn_position
	anchor_position = spawn_position
	configure_for_floor(floor_number)
	_choose_wander_target()


func configure_party(leader: DungeonExplorer, party_slot: int, new_party_title: String) -> void:
	party_leader = leader
	party_title = new_party_title
	party_role = "Lead" if party_slot == 0 else "Scout" if party_slot == 1 else "Guard"
	name_label.text = "%s %s" % [party_title, party_role]


func configure_for_floor(floor_number: int) -> void:
	current_floor = clampi(floor_number, 1, 4)
	max_health = 3 + current_floor * 2
	current_health = max_health
	move_speed = 27.0 + current_floor * 3.0
	attack_hurt_box.damage = 1 + floori(float(current_floor - 1) / 2.0)
	var gear: Array = FLOOR_GEAR.get(current_floor, [])
	if not gear.is_empty():
		carried_items.append(gear.pick_random())


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	attack_time = maxf(attack_time - delta, 0.0)
	attack_animation_time = maxf(attack_animation_time - delta, 0.0)
	path_refresh_time = maxf(path_refresh_time - delta, 0.0)
	var combat_target := _find_combat_target()
	if combat_target != null:
		_handle_combat_target(combat_target, delta)
	else:
		var pickup := _find_nearest_pickup()
		if pickup != null:
			_handle_pickup(pickup, delta)
		else:
			_handle_wander(delta)
	var was_moving := velocity.length_squared() > 0.001
	move_and_slide()
	if was_moving and is_on_wall():
		path_refresh_time = 0.0
	_update_sprite(velocity, delta)


func _handle_combat_target(target: Node2D, delta: float) -> void:
	var offset := target.global_position - global_position
	if offset.length() <= attack_range:
		velocity = Vector2.ZERO
		_face(offset)
		if attack_time <= 0.0:
			_attack(target)
		return
	status_label.text = "Fighting"
	_move_toward_target(target.global_position, delta)


func _handle_pickup(pickup: Node2D, delta: float) -> void:
	var offset := pickup.global_position - global_position
	if offset.length() <= pickup_range:
		if pickup.has_method("take_for_dungeon_explorer"):
			var item_data := pickup.call("take_for_dungeon_explorer") as ItemData
			if item_data != null:
				carried_items.append(item_data)
				collected_items += 1
				status_label.text = "Found loot"
		velocity = Vector2.ZERO
		return
	status_label.text = "Gathering"
	_move_toward_target(pickup.global_position, delta)


func _handle_wander(delta: float) -> void:
	if _follow_party_leader(delta):
		return
	wander_time -= delta
	if wander_time <= 0.0 or global_position.distance_to(wander_target) <= 8.0:
		_choose_wander_target()
	status_label.text = "Exploring"
	_move_toward_target(wander_target, delta)


func _follow_party_leader(delta: float) -> bool:
	if party_leader == null or party_leader == self or not is_instance_valid(party_leader) or party_leader.is_dead:
		return false
	var leader_distance := global_position.distance_to(party_leader.global_position)
	status_label.text = "%s party" % party_title
	if leader_distance <= PARTY_FOLLOW_DISTANCE:
		velocity = Vector2.ZERO
		if party_leader.velocity.length_squared() > 0.001:
			_face(party_leader.velocity)
		return true
	_move_toward_target(party_leader.global_position, delta)
	return true


func _find_combat_target() -> Node2D:
	var player := PlayerManager.player
	if _actively_hostile_to_player() and player != null and global_position.distance_to(player.global_position) <= aggro_range:
		return player
	return _find_nearest_enemy()


func _find_nearest_enemy() -> Enemy:
	var nearest: Enemy
	var nearest_distance := aggro_range
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest


func _find_nearest_pickup() -> Node2D:
	var nearest: Node2D
	var nearest_distance := 96.0
	var player := PlayerManager.player
	for node in get_tree().get_nodes_in_group("item_pickups"):
		var pickup := node as Node2D
		if pickup == null or not is_instance_valid(pickup) or pickup.is_queued_for_deletion():
			continue
		if player != null and pickup.global_position.distance_to(player.global_position) < 48.0:
			continue
		var distance := global_position.distance_to(pickup.global_position)
		if distance < nearest_distance:
			nearest = pickup
			nearest_distance = distance
	return nearest


func _move_toward_target(target_position: Vector2, _delta: float) -> void:
	if path_refresh_time <= 0.0 or navigation_target.distance_to(target_position) > 12.0:
		navigation_target = target_position
		navigation_path = DungeonPathfinder.get_point_path(global_position, target_position)
		navigation_index = 1
		path_refresh_time = 0.45
	var next_position := target_position
	while navigation_index < navigation_path.size() and global_position.distance_to(navigation_path[navigation_index]) <= 6.0:
		navigation_index += 1
	if navigation_index < navigation_path.size():
		next_position = navigation_path[navigation_index]
	else:
		velocity = Vector2.ZERO
		return
	_move_in_direction(next_position - global_position)


func _move_in_direction(offset: Vector2) -> void:
	if offset.length_squared() <= 0.001:
		velocity = Vector2.ZERO
		return
	_face(offset)
	velocity = offset.normalized() * move_speed


func _attack(target: Node2D) -> void:
	attack_time = attack_cooldown
	attack_animation_time = ATTACK_ANIMATION_DURATION
	status_label.text = "Striking"
	attack_hurt_box.position = ATTACK_OFFSETS[facing]
	if target is Enemy:
		var enemy_hitbox := target.get_node_or_null("Hitbox") as HitBox
		if enemy_hitbox != null:
			enemy_hitbox.TakeDamage(attack_hurt_box)
	if _can_harm_player():
		attack_hurt_box.monitoring = true
		get_tree().create_timer(0.14).timeout.connect(_disable_attack_hurt_box, CONNECT_ONE_SHOT)
	var flash_tween := create_tween()
	flash_tween.tween_property(sprite, "modulate", Color(1.25, 1.25, 0.8, 1.0), 0.08)
	flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.16)


func _disable_attack_hurt_box() -> void:
	if is_instance_valid(attack_hurt_box):
		attack_hurt_box.monitoring = false


func _take_damage(hurt_box: HurtBox) -> void:
	if is_dead:
		return
	current_health -= hurt_box.damage
	if _is_player_attack(hurt_box):
		ReputationManager.record_adventurer_harm(current_health <= 0)
		var faction_manager := get_node_or_null("/root/FactionManager")
		if faction_manager != null:
			faction_manager.call("record_adventurer_harm", current_health <= 0)
		var shop_log := get_node_or_null("/root/ShopLog")
		if shop_log != null:
			var outcome := "killed" if current_health <= 0 else "injured"
			shop_log.call("record_dungeon_event", "The Goblin %s an adventurer." % outcome, "combat")
		status_label.text = "Under attack"
	var flash_tween := create_tween()
	flash_tween.tween_property(sprite, "modulate", Color(1.3, 0.55, 0.55, 1.0), 0.06)
	flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)
	if current_health <= 0:
		_die()


func _is_player_attack(hurt_box: HurtBox) -> bool:
	var source := hurt_box.get_parent()
	return source is StoneProjectile or source.get_parent() is Player


func _can_harm_player() -> bool:
	return ReputationManager.get_mood() <= ReputationManager.Mood.NEUTRAL


func _actively_hostile_to_player() -> bool:
	return ReputationManager.get_mood() <= ReputationManager.Mood.WARY


func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	attack_hurt_box.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	status_label.text = "Fallen"
	call_deferred("_drop_carried_items")
	var fade_tween := create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.35)
	fade_tween.tween_callback(queue_free)


func _drop_carried_items() -> void:
	var parent := get_parent()
	if parent == null:
		return
	for index in carried_items.size():
		var pickup := PICKUP_SCENE.instantiate() as item_pickup
		pickup.item_data = carried_items[index]
		parent.add_child(pickup)
		var angle := TAU * float(index) / maxf(float(carried_items.size()), 1.0)
		pickup.global_position = global_position + Vector2(cos(angle), sin(angle)) * 10.0


func _choose_wander_target() -> void:
	wander_time = randf_range(1.4, 3.2)
	wander_target = DungeonPathfinder.get_wander_point(anchor_position, Vector2(88.0, 64.0))
	navigation_target = Vector2.INF


func _face(direction: Vector2) -> void:
	if absf(direction.x) >= absf(direction.y):
		facing = "left" if direction.x < 0.0 else "right"
	else:
		facing = "up" if direction.y < 0.0 else "down"


func _update_sprite(movement: Vector2, delta: float) -> void:
	var base_frame: int = DIRECTION_FRAMES[facing]
	sprite.flip_h = facing == "left"
	if attack_animation_time > 0.0:
		var animation_progress := 1.0 - attack_animation_time / ATTACK_ANIMATION_DURATION
		var attack_frame := clampi(int(animation_progress * ATTACK_FRAME_OFFSETS.size()), 0, ATTACK_FRAME_OFFSETS.size() - 1)
		sprite.frame = base_frame + ATTACK_FRAME_OFFSETS[attack_frame]
		return
	if movement.length_squared() > 0.001:
		walk_time += delta
	else:
		walk_time = 0.0
	var walk_frame := int(walk_time / 0.15) % 4 if walk_time > 0.0 else 0
	sprite.frame = base_frame + walk_frame
