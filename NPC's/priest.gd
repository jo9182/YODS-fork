class_name priest extends CharacterBody2D

# basic stuff the designer fills in
@export var priest_name: String = ""
@export var Sentence: String = ""
@export var opt1: String = ""
@export var opt2: String = ""
@export var res1: String = ""
@export var res2: String = ""

# --- shop stuff ---

# tick this if the npc should be able to buy from the player's shop at all
@export var is_shop_customer: bool = false

# which dialogue button opens the shop?
# 0 = neither (shop opens immediately on interact)
# 1 = button 1 (opt1) opens the shop after res1 is shown
# 2 = button 2 (opt2) opens the shop after res2 is shown
@export_range(0, 2) var shop_trigger_option: int = 0

# how many coins this npc has to spend -- set per npc in the inspector
# this is their personal budget, not the player's gold
@export var coin_amount: int = 100

# --- node refs, boring but needed ---
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

# which listing we're currently showing
var _shop_index: int = 0

# are we in shop browsing mode right now
var _in_shop_mode: bool = false


func _ready() -> void:
	animation_player.play("idle")
	speech.text = Sentence
	char_name.text = priest_name
	button.text = opt1
	button_2.text = opt2


func _unhandled_input(event: InputEvent) -> void:
	# check if player is close enough to interact
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

		# skip dialogue entirely and go straight to shop if trigger is 0
		if is_shop_customer and shop_trigger_option == 0:
			_enter_shop_mode()


func _on_area_2d_body_entered(body: Node2D) -> void:
	control.visible = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	# player walked away, clean everything up
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
	# buy button when in shop mode
	if _in_shop_mode:
		_on_shop_buy_pressed()
		return

	speech.text = res1
	button.visible = false
	button_2.visible = false
	exit.visible = true

	# open shop after opt1 if that's what's configured
	if is_shop_customer and shop_trigger_option == 1:
		await get_tree().create_timer(1.2).timeout
		_enter_shop_mode()


func _on_button_2_pressed() -> void:
	# next item button when in shop mode
	if _in_shop_mode:
		_on_shop_next_pressed()
		return

	speech.text = res2
	button.visible = false
	button_2.visible = false
	exit.visible = true

	# same but for opt2
	if is_shop_customer and shop_trigger_option == 2:
		await get_tree().create_timer(1.2).timeout
		_enter_shop_mode()


func _on_exit_pressed() -> void:
	control.visible = false
	secondary_control.visible = false
	color_rect.visible = false
	_in_shop_mode = false
	_shop_index = 0


# --- shop customer mode -------------------------------------------------------

func _enter_shop_mode() -> void:
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

	# clamp just in case the list shrank after a purchase
	_shop_index = clamp(_shop_index, 0, listings.size() - 1)
	var listing: ShopListing = listings[_shop_index]

	var total = listings.size()
	speech.text = "%s\nPrice: %d gold\n(%d of %d)" % [
		listing.item_data.name,
		listing.price,
		_shop_index + 1,
		total
	]

	button.text = "Buy"
	button.visible = true

	# no point showing next if there's only one item
	button_2.visible = total > 1
	button_2.text = "Next"

	exit.visible = true


func _on_shop_buy_pressed() -> void:
	var listings = ShopManager.listings
	if listings.is_empty():
		return

	var listing: ShopListing = listings[_shop_index]

	# check the npc's own wallet -- not the player's gold
	if coin_amount < listing.price:
		speech.text = "I can't afford this!"
		button.visible = false
		button_2.visible = false
		exit.visible = true
		return

	# deduct from the npc's budget and complete the sale
	# ShopManager.sell() handles adding gold to PlayerStats
	coin_amount -= listing.price
	ShopManager.sell(listing)

	if ShopManager.listings.is_empty():
		speech.text = "Thanks for doing business!"
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
	# wrap around to the beginning
	_shop_index = (_shop_index + 1) % listings.size()
	_show_current_listing()
