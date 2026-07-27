class_name Customer extends CharacterBody2D

const ST_ENTERING := 0
const ST_BROWSING := 1
const ST_EXITING := 2
const ST_GONE := 3

@export var customer_data: CustomerData

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var name_label: Label = $NameLabel
@onready var visit_timer: Timer = $VisitTimer
@onready var buy_timer: Timer = $BuyTimer

var _state := ST_ENTERING
var _target_position: Vector2
var _current_budget: int
var _entry_point: Vector2
var _exit_point: Vector2
var _browsing_spot: Vector2

signal customer_left(customer: Customer)


func _ready() -> void:
	if customer_data:
		_current_budget = randi_range(customer_data.min_budget, customer_data.max_budget)
		name_label.text = customer_data.customer_name
		if not customer_data.greeting.is_empty():
			_show_bubble(customer_data.greeting)
		_setup_sprite_deferred.call_deferred()
	else:
		_current_budget = 0

	visit_timer.timeout.connect(_on_visit_timeout)
	buy_timer.timeout.connect(_on_buy_check)


func _setup_sprite_deferred() -> void:
	if not customer_data:
		return
	sprite_2d.texture = customer_data.texture
	sprite_2d.scale = customer_data.sprite_scale
	sprite_2d.region_enabled = false
	sprite_2d.hframes = customer_data.hframes
	sprite_2d.vframes = customer_data.vframes
	animation_player.play("idle")


func init_spawn(entry: Vector2, exit_pos: Vector2, spot: Vector2) -> void:
	_entry_point = entry
	_exit_point = exit_pos
	_browsing_spot = spot
	global_position = _entry_point
	_target_position = _browsing_spot
	_state = ST_ENTERING
	visit_timer.start(customer_data.visit_duration if customer_data else 25.0)
	buy_timer.start(4.0)


func _physics_process(delta: float) -> void:
	match _state:
		ST_ENTERING, ST_EXITING:
			_move_toward_target(delta)
		ST_BROWSING:
			velocity = Vector2.ZERO
			animation_player.play("idle")


func _move_toward_target(delta: float) -> void:
	var direction := (_target_position - global_position).normalized()
	var speed := customer_data.walk_speed if customer_data else 50.0
	velocity = direction * speed
	move_and_slide()

	# Choose walk animation based on primary movement direction
	if abs(direction.x) >= abs(direction.y):
		if direction.x < 0:
			animation_player.play("walk_left")
		else:
			animation_player.play("walk_right")
	else:
		if direction.y < 0:
			animation_player.play("walk_up")
		else:
			animation_player.play("walk_down")

	if global_position.distance_to(_target_position) < 6.0:
		velocity = Vector2.ZERO
		global_position = _target_position
		if _state == ST_ENTERING:
			_state = ST_BROWSING
			animation_player.play("idle")
		elif _state == ST_EXITING:
			_state = ST_GONE
			customer_left.emit(self)
			queue_free()


func _on_buy_check() -> void:
	if _state != ST_BROWSING:
		return
	if _current_budget <= 0:
		_start_exiting()
		return

	var mood = ReputationManager.get_mood()
	if mood == ReputationManager.Mood.HOSTILE:
		_start_exiting()
		return

	if ShopManager.listings.is_empty():
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


func _purchase(listing: ShopListing) -> void:
	_current_budget -= listing.price
	var buyer_name := customer_data.customer_name if customer_data else "Customer"
	ShopManager.sell(listing, buyer_name)
	_show_popup(listing.item_data.name, listing.price)


func _on_visit_timeout() -> void:
	_start_exiting()


func _start_exiting() -> void:
	if _state == ST_EXITING or _state == ST_GONE:
		return
	_state = ST_EXITING
	_target_position = _exit_point
	buy_timer.stop()
	visit_timer.stop()
	_show_bubble("Goodbye!")


func _show_bubble(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", Color(1, 1, 0.8))
	lbl.add_theme_font_size_override("font_size", 10)
	call_deferred("_add_bubble", lbl)


func _add_bubble(lbl: Label) -> void:
	get_parent().add_child(lbl)
	lbl.global_position = global_position + Vector2(-40, -32)
	var tween := lbl.create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position:y", lbl.position.y - 25, 2.0).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 0.0, 2.0).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(lbl.queue_free)


func _show_popup(item_name: String, price: int) -> void:
	var lbl := Label.new()
	lbl.text = "Bought: %s (%dg)" % [item_name, price]
	lbl.add_theme_color_override("font_color", Color(0.2, 1, 0.2))
	lbl.add_theme_font_size_override("font_size", 10)
	get_parent().add_child(lbl)
	lbl.global_position = global_position + Vector2(-30, -44)
	var tween := lbl.create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position:y", lbl.position.y - 30, 1.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 0.0, 1.2).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(lbl.queue_free)
