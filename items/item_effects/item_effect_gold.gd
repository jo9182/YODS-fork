class_name ItemEffectGold extends ItemEffect

@export var amount: int = 1

func use() -> void:
	PlayerStats.add_gold(amount)
