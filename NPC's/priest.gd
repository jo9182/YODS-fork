class_name priest extends CharacterBody2D

@export var priest_name: String = ""
@export var Sentence: String = ""
@export var opt1: String = ""
@export var opt2: String = ""
@export var res1: String = ""
@export var res2: String = ""

@export var is_shop_customer: bool = false
@export_range(0, 2) var shop_trigger_option: int = 0
@export var coin_amount: int = 100

# --- auto buy ---
# if true the NPC will browse the shop on their own and buy
# what they can afford without the player needing to interact
@export var auto_buy: bool = false

# seconds between each auto-buy check
@export var auto_buy_interval: float = 30.0

@onready var marker_2d: Marker2D = $Marker2D
@onready var marker_2d_2: Marker2D = $Marker2D2
@onready var marker_2d_3: Marker2D = $Marker2D3
@onready var marker_2d_4: Marker2D = $Marker2D4
@onready var control: Control = $CanvasLayer/Control
@onready var label: Label = $CanvasLayer/Control/Label
@onready var secondary_control: Control = $"CanvasLayer/Control/Secondary control"
@onready var speech: TextEdit = $"CanvasLayer/Control/Secondary control/Speech"
@onready var button: Button = $"CanvasLayer/Control/Secondary control/Button"
@onready var button_2: Button = $"CanvasLayer/Control/Secondary control/Button2"
@onready var exit: Button = $"CanvasLayer/Control/Secondary control/Exit"
@onready var sprite_2d: Sprite2D = $"CanvasLayer/Control/Secondary control/Sprite2D"
@onready var char_name: Label = $"CanvasLayer/Control/Secondary control/Char_Name"
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var color_rect: ColorRect = $CanvasLayer/ColorRect

var _shop_index: int = 0
var _in_shop_mode: bool = false
var _effective_budget: int = 0
var _auto_buy_timer: Timer = null


func _ready() -> void:
	animation_player.play("idle")
	speech.text = Sentence
	char_name.text = priest_name
	button.text = opt1
	button_2.text = opt2

	if auto_buy and is_shop_customer:
		_auto_buy_timer = Timer.new()
		_auto_buy_timer.wait_time = auto_buy_interval
		_auto_buy_timer.autostart = true
		_auto_buy_timer.timeout.connect(_run_auto_buy)
		add_child(_auto_buy_timer)


func _unhandled_input(event: InputEvent) -> void:
	var in_range = (
		PlayerManager.player.global_position.x > marker_2d.global_position.x and
		PlayerManager.player.global_position.x < marker_2d_3.global_position.x and
		PlayerManager.player.global_position.y > marker_2d_4.global_position.y and
		PlayerManager.player.global_position.y < marker_2d_2.global_position.y
	)

	if in_range and event.is_action_pressed("interact"):
		color_rect.visible = true
		secondary_control.visible = true
		label.visible = false

		if is_shop_customer and shop_trigger_option == 0:
			_enter_shop_mode()


func _on_area_2d_body_entered(body: Node2D) -> void:
	control.visible = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	control.visible = false
	secondary_control.visible = false
	label.visible = true
	color_rect.visible = false
	exit.visible = false
	_in_shop_mode = false
	_shop_index = 0
	_reset_dialogue()


# --- normal dialogue ----------------------------------------------------------

func _reset_dialogue() -> void:
	speech.text = Sentence
	button.text = opt1
	button_2.text = opt2
	button.visible = true
	button_2.visible = true
	exit.visible = false


func _on_button_pressed() -> void:
	if _in_shop_mode:
		_on_shop_buy_pressed()
		return

	speech.text = res1
	button.visible = false
	button_2.visible = false
	exit.visible = true

	if is_shop_customer and shop_trigger_option == 1:
		await get_tree().create_timer(1.2).timeout
		_enter_shop_mode()


func _on_button_2_pressed() -> void:
	if _in_shop_mode:
		_on_shop_next_pressed()
		return

	speech.text = res2
	button.visible = false
	button_2.visible = false
	exit.visible = true

	if is_shop_customer and shop_trigger_option == 2:
		await get_tree().create_timer(1.2).timeout
		_enter_shop_mode()


func _on_exit_pressed() -> void:
	control.visible = false
	secondary_control.visible = false
	color_rect.visible = false
	_in_shop_mode = false
	_shop_index = 0


# --- shop customer mode (manual) ---------------------------------------------

func _enter_shop_mode() -> void:
	var mood = ReputationManager.get_mood()

	if mood == ReputationManager.Mood.HOSTILE:
		speech.text = _hostile_line()
		button.visible = false
		button_2.visible = false
		exit.visible = true
		return

	_effective_budget = int(coin_amount * ReputationManager.get_budget_multiplier())
	_in_shop_mode = true
	_shop_index = 0
	_show_current_listing()


func _show_current_listing() -> void:
	var listings = ShopManager.listings

	if listings.is_empty():
		speech.text = "Hmm, nothing seems to be for sale right now."
		button.visible = false
		button_2.visible = false
		exit.visible = true
		return

	_shop_index = clamp(_shop_index, 0, listings.size() - 1)
	var listing: ShopListing = listings[_shop_index]

	var tolerance = ReputationManager.get_price_tolerance()
	var base = listing.item_data.base_value
	var overpriced = base > 0 and listing.price > base * tolerance

	var total = listings.size()
	var price_note = ""
	if overpriced:
		price_note = "\n(That seems too expensive...)"
	elif base > 0 and listing.price <= base:
		price_note = "\n(What a fair price!)"

	speech.text = "%s\nPrice: %d gold\n(%d of %d)%s" % [
		listing.item_data.name,
		listing.price,
		_shop_index + 1,
		total,
		price_note
	]

	var can_buy = not overpriced and _effective_budget >= listing.price
	button.text = "Buy"
	button.visible = can_buy
	button_2.visible = total > 1
	button_2.text = "Next"
	exit.visible = true


func _on_shop_buy_pressed() -> void:
	var listings = ShopManager.listings
	if listings.is_empty():
		return

	var listing: ShopListing = listings[_shop_index]

	if _effective_budget < listing.price:
		speech.text = "I can't afford this!"
		button.visible = false
		button_2.visible = false
		exit.visible = true
		return

	_effective_budget -= listing.price
	coin_amount -= listing.price
	ShopManager.sell(listing)

	if ShopManager.listings.is_empty():
		speech.text = _thanks_line()
		button.visible = false
		button_2.visible = false
		exit.visible = true
	else:
		_shop_index = clamp(_shop_index, 0, ShopManager.listings.size() - 1)
		_show_current_listing()


func _on_shop_next_pressed() -> void:
	var listings = ShopManager.listings
	if listings.is_empty():
		return
	_shop_index = (_shop_index + 1) % listings.size()
	_show_current_listing()


# --- auto buy (silent, no UI) ------------------------------------------------

func _run_auto_buy() -> void:
	if ShopManager.listings.is_empty():
		return

	var mood = ReputationManager.get_mood()
	if mood == ReputationManager.Mood.HOSTILE:
		return

	var budget = int(coin_amount * ReputationManager.get_budget_multiplier())
	var tolerance = ReputationManager.get_price_tolerance()

	# shuffle a copy so the NPC doesn't always buy the first item listed
	var listings = ShopManager.listings.duplicate()
	listings.shuffle()

	for listing in listings:
		if budget <= 0:
			break

		var base = listing.item_data.base_value
		var overpriced = base > 0 and listing.price > base * tolerance

		if overpriced:
			continue
		if listing.price > budget:
			continue

		# buy one unit
		budget -= listing.price
		coin_amount -= listing.price
		ShopManager.sell(listing)

		# small floating label so the player knows something was sold
		_show_sale_popup(listing.item_data.name, listing.price)

		# small delay between purchases so it doesn't feel instant
		await get_tree().create_timer(0.4).timeout


func _show_sale_popup(item_name: String, price: int) -> void:
	# spawns a brief label above the NPC that floats up and fades out
	var lbl = Label.new()
	lbl.text = "Sold: %s (%dg)" % [item_name, price]
	lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	get_parent().add_child(lbl)
	lbl.global_position = global_position + Vector2(-30, -40)

	var tween = lbl.create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position:y", lbl.position.y - 30, 1.2)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 0.0, 1.2)\
		.set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(lbl.queue_free)


# --- mood flavoured lines ----------------------------------------------------

func _hostile_line() -> String:
	return "I've heard how you treat your customers. I won't be shopping here."


func _thanks_line() -> String:
	match ReputationManager.get_mood():
		ReputationManager.Mood.BELOVED:
			return "Always a pleasure doing business with you!"
		ReputationManager.Mood.FRIENDLY:
			return "Thanks! I'll be back."
		_:
			return "Thanks for doing business!"
