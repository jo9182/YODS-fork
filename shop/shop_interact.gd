class_name shop_interact extends Area2D
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var control: Control = $CanvasLayer/Control
@onready var button: Button = $CanvasLayer/Control/Button
@onready var item_list: ItemList = $CanvasLayer/Control/ItemList


func _ready() -> void:
	
	pass

func _on_body_entered(_body: Node2D) -> void:
	print("helpful")
	button.visible = true
	pass # Replace with function body.



func _on_button_pressed() -> void:
	button.visible = false
	item_list.visible = true
	print("WORED")
	
	pass 


func _on_body_exited(_body: Node2D) -> void:
	button.visible = false
	item_list.visible = false
	pass 
