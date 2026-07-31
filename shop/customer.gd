class_name Customer extends CharacterBody2D

const ST_ENTERING := 0
const ST_BROWSING := 1
const ST_EXITING := 2
const ST_GONE := 3

const ARRIVAL_DISTANCE := 6.0
const BROWSE_RADIUS := 18.0
const BROWSE_PAUSE_MIN := 1.25
const BROWSE_PAUSE_MAX := 3.0
const WALK_BOB_SPEED := 12.0
const WALK_BOB_HEIGHT := 0.75
const WALK_ANIMATION_FPS := 7.0
const WALK_FRAME_COUNT := 4
const IDLE_SPRITE_Y := -18.0
const ENTRY_DIALOGUE_DISTANCE := 130.0
const CUSTOMER_DIALOGUE = preload("res://shop/customer_dialogue.gd")
const DIRECTION_ROWS := {
	"down": 0,
	"left": 6,
	"right": 2,
	"up": 4,
}

@export var customer_data: CustomerData

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var name_label: Label = $NameLabel
@onready var status_label: Label = $StatusLabel
@onready var visit_timer: Timer = $VisitTimer
@onready var buy_timer: Timer = $BuyTimer

var _state := ST_ENTERING
var _target_position: Vector2
var _current_budget: int
var _entry_point: Vector2
var _exit_point: Vector2
var _browsing_spot: Vector2
var _customer_type := ""
var _faction_id := ""
var _display_name := "Customer"
var _entry_dialogue_shown := false
var _facing := "down"
var _is_walking := false
var _browse_pause_remaining := 0.0
var _walk_time := 0.0
var _status_tween: Tween
var _is_tax_collector := false
var _visit_recorded := false

signal customer_left(customer: Customer)


func _ready() -> void:
	if customer_data:
		_is_tax_collector = customer_data.is_tax_collector
		if _is_tax_collector:
			_current_budget = 0
		else:
			_current_budget = roundi(
				randi_range(customer_data.min_budget, customer_data.max_budget)
				* ReputationManager.get_budget_multiplier()
				* ShopUpgradeManager.get_customer_budget_multiplier()
				* (1.0 + PlayerStats.customer_budget_bonus)
			)
		_customer_type = customer_data.customer_name
		_faction_id = str(customer_data.faction_id)
		_display_name = CUSTOMER_DIALOGUE.pick_name(_customer_type)
		name_label.text = _display_name
		_setup_sprite()
	else:
		_current_budget = 0

	visit_timer.timeout.connect(_on_visit_timeout)
	buy_timer.timeout.connect(_on_buy_check)
	_show_idle()


func _setup_sprite() -> void:
	if not customer_data:
		return
	sprite_2d.texture = customer_data.texture
	sprite_2d.modulate = customer_data.sprite_modulate
	sprite_2d.scale = customer_data.sprite_scale
	sprite_2d.region_enabled = false
	sprite_2d.hframes = customer_data.hframes
	sprite_2d.vframes = customer_data.vframes
	_show_idle()


func init_spawn(entry: Vector2, exit_pos: Vector2, spot: Vector2) -> void:
	_entry_point = entry
	_exit_point = exit_pos
	_browsing_spot = spot
	global_position = _entry_point
	_target_position = _browsing_spot
	_state = ST_ENTERING
	_entry_dialogue_shown = false
	visit_timer.start(customer_data.visit_duration if customer_data else 25.0)
	buy_timer.start(4.0)


func _physics_process(delta: float) -> void:
	match _state:
		ST_ENTERING, ST_EXITING:
			_move_toward_target(delta)
		ST_BROWSING:
			_browse(delta)


func _process(delta: float) -> void:
	if _is_walking:
		_walk_time += delta
		sprite_2d.position.y = IDLE_SPRITE_Y + sin(_walk_time * WALK_BOB_SPEED) * WALK_BOB_HEIGHT
		var walk_frame := int(_walk_time * WALK_ANIMATION_FPS) % WALK_FRAME_COUNT
		sprite_2d.frame = _direction_row() * sprite_2d.hframes + walk_frame
	else:
		sprite_2d.position.y = move_toward(sprite_2d.position.y, IDLE_SPRITE_Y, delta * 8.0)


func _move_toward_target(delta: float) -> void:
	var target_offset := _target_position - global_position
	if target_offset.length() <= ARRIVAL_DISTANCE:
		global_position = _target_position
		velocity = Vector2.ZERO
		_show_idle()
		_handle_target_reached()
		return

	var direction := target_offset.normalized()
	var speed := customer_data.walk_speed if customer_data else 50.0
	velocity = velocity.move_toward(direction * speed, speed * 10.0 * delta)
	move_and_slide()
	_show_entry_dialogue_when_visible()
	_play_walk_animation(direction)


func _browse(delta: float) -> void:
	if _browse_pause_remaining > 0.0:
		_browse_pause_remaining -= delta
		velocity = Vector2.ZERO
		_show_idle()
		if _browse_pause_remaining <= 0.0:
			_choose_browse_target()
		return

	_move_toward_target(delta)


func _handle_target_reached() -> void:
	if _state == ST_ENTERING:
		_state = ST_BROWSING
		_record_shop_visit()
		if _is_tax_collector:
			buy_timer.stop()
			_show_status(_dialogue_line("browse", "Reviewing your account."), Color(0.93, 0.65, 0.26), 1.2)
			get_tree().create_timer(1.35).timeout.connect(_complete_tax_visit, CONNECT_ONE_SHOT)
			return
		_start_browse_pause()
		_show_status(_dialogue_line("browse", "Let me have a look around."), Color(0.85, 0.9, 1.0), 1.8)
	elif _state == ST_BROWSING:
		_start_browse_pause()
	elif _state == ST_EXITING:
		_state = ST_GONE
		customer_left.emit(self)
		queue_free()


func _complete_tax_visit() -> void:
	if _state != ST_BROWSING:
		return
	_show_status("Our arrangement remains in effect.", Color(0.93, 0.65, 0.26), 1.6)
	get_tree().create_timer(1.65).timeout.connect(_start_exiting, CONNECT_ONE_SHOT)


func _show_entry_dialogue_when_visible() -> void:
	if _state != ST_ENTERING or _entry_dialogue_shown:
		return
	if global_position.distance_to(_entry_point) < ENTRY_DIALOGUE_DISTANCE:
		return

	_entry_dialogue_shown = true
	_show_status(_dialogue_line("entry", customer_data.greeting), Color(1.0, 1.0, 0.8), 2.5)


func _choose_browse_target() -> void:
	var offset := Vector2(
		randf_range(-BROWSE_RADIUS, BROWSE_RADIUS),
		randf_range(-BROWSE_RADIUS, BROWSE_RADIUS)
	)
	_target_position = _browsing_spot + offset.limit_length(BROWSE_RADIUS)


func _start_browse_pause() -> void:
	_browse_pause_remaining = randf_range(BROWSE_PAUSE_MIN, BROWSE_PAUSE_MAX)
	_show_idle()


func _play_walk_animation(direction: Vector2) -> void:
	_facing = _direction_name(direction)
	if not _is_walking:
		_walk_time = 0.0
	_is_walking = true


func _show_idle() -> void:
	_is_walking = false
	if is_instance_valid(sprite_2d):
		sprite_2d.frame = _direction_row() * sprite_2d.hframes


func _direction_row() -> int:
	return DIRECTION_ROWS[_facing]


func _direction_name(direction: Vector2) -> String:
	if abs(direction.x) >= abs(direction.y):
		return "left" if direction.x < 0.0 else "right"
	return "up" if direction.y < 0.0 else "down"


func _on_buy_check() -> void:
	if _state != ST_BROWSING:
		return
	if _current_budget <= 0:
		_start_exiting()
		return

	var mood = ReputationManager.get_mood()
	if mood == ReputationManager.Mood.HOSTILE:
		_show_status(_dialogue_line("hostile", "Not welcome here."), Color(1.0, 0.55, 0.55), 1.5)
		_start_exiting()
		return

	if ShopManager.listings.is_empty():
		_show_status(_dialogue_line("empty", "Nothing catches my eye."), Color(0.85, 0.85, 0.85), 1.5)
		_start_exiting()
		return

	_attempt_purchase()


func _attempt_purchase() -> void:
	var listings := ShopManager.listings.duplicate()
	listings.shuffle()

	var tolerance := ReputationManager.get_price_tolerance()
	var pref_mult := customer_data.preferred_price_multiplier if customer_data else 1.0

	if customer_data and not customer_data.preferred_item_names.is_empty():
		for listing in listings:
			if _current_budget <= 0:
				return
			if customer_data.preferred_item_names.has(listing.item_data.name):
				var base: float = listing.item_data.base_value
				var max_price: float = base * tolerance * pref_mult
				if listing.price <= _current_budget and listing.price <= max_price:
					_purchase(listing)
					return

	for listing in listings:
		if _current_budget <= 0:
			return
		var base: float = listing.item_data.base_value
		if listing.price <= _current_budget and listing.price <= base * tolerance:
			_purchase(listing)
			return

	_show_status(_dialogue_line("pricey", "Too expensive!"), Color(1.0, 0.7, 0.45), 1.5)
	_start_exiting()


func _purchase(listing: ShopListing) -> void:
	_current_budget -= listing.price
	var buyer_name := _display_name
	ShopManager.sell(listing, buyer_name, _faction_id)
	var purchase_line := _dialogue_line("purchase", "Bought {item}!")
	_show_status(purchase_line.replace("{item}", listing.item_data.name), Color(0.45, 1.0, 0.55), 1.8)


func _on_visit_timeout() -> void:
	_start_exiting()


func _start_exiting() -> void:
	if _state == ST_EXITING or _state == ST_GONE:
		return
	_state = ST_EXITING
	_target_position = _exit_point
	buy_timer.stop()
	visit_timer.stop()
	if status_label.text.is_empty() or status_label.modulate.a <= 0.0:
		_show_status(_dialogue_line("farewell", "Goodbye!"), Color(1.0, 1.0, 0.8), 1.2)


func _dialogue_line(category: String, fallback: String) -> String:
	if category == "entry" and not _is_tax_collector:
		var faction_line := CUSTOMER_DIALOGUE.pick_faction_line(_faction_id, category, "")
		if not faction_line.is_empty():
			return faction_line
	return CUSTOMER_DIALOGUE.pick_line(_customer_type, category, fallback)


func _record_shop_visit() -> void:
	if _visit_recorded:
		return
	_visit_recorded = true
	var shop_log := get_node_or_null("/root/ShopLog")
	if shop_log != null:
		shop_log.call("record_visitor", _display_name, _customer_type, _faction_id)
	if _is_tax_collector or _faction_id.is_empty():
		return
	var faction_manager := get_node_or_null("/root/FactionManager")
	if faction_manager != null:
		faction_manager.call("record_customer_visit", _faction_id)
	var commission_manager := get_node_or_null("/root/CommissionManager")
	if commission_manager != null:
		commission_manager.call("record_customer_visit", _faction_id)


func _show_status(message: String, color: Color, duration: float) -> void:
	if not is_instance_valid(status_label):
		return
	if is_instance_valid(_status_tween):
		_status_tween.kill()

	status_label.text = message
	status_label.add_theme_color_override("font_color", color)
	status_label.modulate = Color.WHITE
	status_label.show()

	_status_tween = create_tween()
	_status_tween.tween_interval(duration)
	_status_tween.tween_property(status_label, "modulate:a", 0.0, 0.35)
	_status_tween.tween_callback(status_label.hide)
