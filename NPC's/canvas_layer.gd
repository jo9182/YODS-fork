extends CanvasLayer
@export var res1 : String = ""
@export var res2 : String = ""
@onready var control: Control = $Control
@onready var label: Label = $Control/Label
@onready var secondary_control: Control = $"Control/Secondary control"
@onready var speech: RichTextLabel = $"Control/Secondary control/SpeechPanel/Content/Speech"
@onready var button: Button = $"Control/Secondary control/Button"
@onready var button_2: Button = $"Control/Secondary control/Button2"
@onready var exit: Button = $"Control/Secondary control/Exit"
@onready var sprite_2d: Sprite2D = $"Control/Secondary control/Sprite2D"
@onready var char_name: Label = $"Control/Secondary control/Char_Name"

#func _process(delta: float) -> void:
	#button.pressed.connect(_on_button_pressed)
	#button_2.pressed.connect(_on_button_2_pressed)
	#pass

func _on_exit_pressed() -> void:
	control.visible = false
	pass # Replace with function body.


func _on_button_2_pressed() -> void:
	print("w")
	speech.text = res2
	exit.visible = true
	pass # Replace with function body.


func _on_button_pressed() -> void:
	print("x")
	speech.text = res1
	exit.visible = true
	pass # Replace with function body.
