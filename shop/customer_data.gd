class_name CustomerData extends Resource

@export var customer_name: String = "Customer"
@export var texture: Texture2D
@export var hframes: int = 1
@export var vframes: int = 1
@export var anim_frames: int = 3
@export var sprite_scale: Vector2 = Vector2(2.0, 2.0)
@export var sprite_modulate: Color = Color.WHITE
@export var min_budget: int = 50
@export var max_budget: int = 150
@export var preferred_item_names: Array[String] = []
@export var preferred_price_multiplier: float = 1.5
@export var visit_duration: float = 25.0
@export var spawn_weight: float = 1.0
@export var walk_speed: float = 50.0
@export var is_tax_collector := false
@export_multiline var greeting: String = ""
