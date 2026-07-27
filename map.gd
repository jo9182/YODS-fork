class_name map extends CanvasLayer
@onready var control: Control = $Control
@onready var color_rect: ColorRect = $Control/ColorRect
@onready var lvl_1: Button = $Control/Lvl1
@onready var lvl_2: Button = $Control/Lvl2
@onready var lvl_3: Button = $Control/Lvl3
@onready var lvl_4: Button = $Control/Lvl4
@onready var lvl_5: Button = $Control/Lvl5
@onready var exit: Button = $Control/exit



func _on_lvl_1_pressed() -> void:
	lvl_1.visible = false
	lvl_2.visible = false
	lvl_3.visible = false
	lvl_4.visible = false
	lvl_5.visible = false
	#map1.visible = true
	exit.visible = true
	pass # Replace with function body.
	
	


func _on_lvl_2_pressed() -> void:
	lvl_1.visible = false
	lvl_2.visible = false
	lvl_3.visible = false
	lvl_4.visible = false
	lvl_5.visible = false
	#map2.visible = true
	exit.visible = true
	pass # Replace with function body.
	



func _on_lvl_3_pressed() -> void:
	lvl_1.visible = false
	lvl_2.visible = false
	lvl_3.visible = false
	lvl_4.visible = false
	lvl_5.visible = false
	#map3.visible = true
	exit.visible = true
	pass # Replace with function body.
	



func _on_lvl_4_pressed() -> void:
	lvl_1.visible = false
	lvl_2.visible = false
	lvl_3.visible = false
	lvl_4.visible = false
	lvl_5.visible = false
	#map4.visible = true
	exit.visible = true
	pass # Replace with function body.
	



func _on_lvl_5_pressed() -> void:
	lvl_1.visible = false
	lvl_2.visible = false
	lvl_3.visible = false
	lvl_4.visible = false
	lvl_5.visible = false
	#map5.visible = true
	exit.visible = true
	pass # Replace with function body.


func _on_exit_pressed() -> void:
	mapreset()
	self.visible = false
	pass # Replace with function body.

func mapreset() -> void:
	exit.visible = false
	#map1.visible = false
	#map2.visible = false
	#map3.visible = false
	#map4.visible = false
	#map5.visible = false
	lvl_1.visible = true
	lvl_2.visible = true
	lvl_3.visible = true
	lvl_4.visible = true
	lvl_5.visible = true
	
