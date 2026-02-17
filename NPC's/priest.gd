class_name priest extends CharacterBody2D
@export var priest_name : String = ""
@export var Sentence : String = ""
@export var opt1 : String = ""
@export var opt2 : String = ""
@export var res1 : String = ""
@export var res2 : String = ""
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

func _ready() -> void:
	animation_player.play("idle")
	speech.text = Sentence
	char_name.text = priest_name
	button.text = opt1
	button_2.text = opt2

func _unhandled_input(event: InputEvent) -> void:
	if PlayerManager.player.global_position.x > marker_2d.global_position.x and PlayerManager.player.global_position.x < marker_2d_3.global_position.x and PlayerManager.player.global_position.y > marker_2d_4.global_position.y and PlayerManager.player.global_position.y < marker_2d_2.global_position.y:
		if event.is_action_pressed("interact"):
			color_rect.visible = true
			secondary_control.visible = true
			label.visible = false
			print("works")


func _on_area_2d_body_entered(body: Node2D) -> void:
	control.visible = true
	
	pass # Replace with function body.

func _on_area_2d_body_exited(body: Node2D) -> void:
	control.visible = false
	secondary_control.visible = false
	label.visible = true
	speech.text = Sentence
	button.visible = true
	button_2.visible = true
	color_rect.visible = false
	exit.visible = false


func _on_button_pressed() -> void:
	exit.visible = true
	button.visible = false
	button_2.visible = false
	speech.text = res1
	pass # Replace with function body.


func _on_button_2_pressed() -> void:
	speech.text = res2
	button.visible = false
	button_2.visible = false
	exit.visible = true
	pass # Replace with function body.


func _on_exit_pressed() -> void:
	control.visible = false
	secondary_control.visible = false
	color_rect.visible = false
	pass # Replace with function body.
