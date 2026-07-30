class_name CustomerManager extends Node

@export var customer_types: Array[CustomerData] = []
@export var max_customers: int = 2
@export var spawn_cooldown: float = 8.0

@onready var entry_point: Marker2D = $EntryPoint
@onready var exit_point: Marker2D = $ExitPoint

var _active_customers: Array[Customer] = []
var _spawn_timer: float = 0.0
var _browse_spots: Array[Marker2D] = []

const CUSTOMER_SCENE := preload("res://shop/customer.tscn")


func _ready() -> void:
	for child in get_children():
		if child is Marker2D and child.name.begins_with("BrowseSpot"):
			_browse_spots.append(child)
	_spawn_timer = 3.0 * ShopUpgradeManager.get_customer_spawn_multiplier()


func _process(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer <= 0 and _active_customers.size() < max_customers and not customer_types.is_empty():
		_spawn_customer()
		_spawn_timer = _get_spawn_cooldown()


func _spawn_customer() -> void:
	var selected := _pick_weighted()
	if not selected:
		return

	var spot := _find_available_spot()
	if not spot:
		return

	var customer: Customer = CUSTOMER_SCENE.instantiate()
	customer.customer_data = selected
	add_child(customer)
	customer.init_spawn(entry_point.global_position, exit_point.global_position, spot.global_position)
	customer.customer_left.connect(_on_customer_left)
	_active_customers.append(customer)
	var commission_manager := get_node_or_null("/root/CommissionManager")
	if commission_manager != null:
		commission_manager.call("record_customer_visit")


func _pick_weighted() -> CustomerData:
	var total_weight := 0.0
	for ct in customer_types:
		total_weight += ct.spawn_weight
	if total_weight <= 0:
		return null

	var roll := randf() * total_weight
	var cumulative := 0.0
	for ct in customer_types:
		cumulative += ct.spawn_weight
		if roll <= cumulative:
			return ct
	return customer_types.back()


func _find_available_spot() -> Marker2D:
	if _browse_spots.is_empty():
		return entry_point

	var available: Array[Marker2D] = []
	for spot in _browse_spots:
		var occupied := false
		for c in _active_customers:
			if c._browsing_spot.distance_to(spot.global_position) < 24.0:
				occupied = true
				break
		if not occupied:
			available.append(spot)

	if available.is_empty():
		return _browse_spots[randi() % _browse_spots.size()]
	return available[randi() % available.size()]


func _on_customer_left(customer: Customer) -> void:
	_active_customers.erase(customer)


func _get_spawn_cooldown() -> float:
	var altar_multiplier := maxf(0.5, 1.0 - PlayerStats.customer_spawn_reduction)
	return spawn_cooldown * ShopUpgradeManager.get_customer_spawn_multiplier() * altar_multiplier
