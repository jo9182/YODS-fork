extends CanvasLayer

var hearts: Array[HeartGUI] = []

# grab the label you made in the scene
@onready var coin_display: Label = $Control/coinDisplay


func _ready():
	for child in $Control/HFlowContainer.get_children():
		if child is HeartGUI:
			hearts.append(child)
			child.visible = false

	# update the display whenever gold changes
	PlayerStats.gold_changed.connect(_on_gold_changed)

	# set the initial value right away so it's not blank at startup
	_on_gold_changed(PlayerStats.gold)


func _on_gold_changed(new_amount: int) -> void:
	coin_display.text = "Gold: %d" % new_amount


func update_hp(_hp: int, _max_hp: int) -> void:
	update_max_hp(_max_hp)
	for i in _max_hp:
		update_heart(i, _hp)


func update_heart(_index: int, _hp: int) -> void:
	var _value: int = clampi(_hp - _index * 2, 0, 2)
	hearts[_index].value = _value


func update_max_hp(_max_hp: int) -> void:
	var heart_count: int = roundi(_max_hp * 0.5)
	for i in hearts.size():
		if i < heart_count:
			hearts[i].visible = true
		else:
			hearts[i].visible = false
