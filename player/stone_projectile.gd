class_name StoneProjectile extends Area2D

@export var speed: float = 280.0
@export var max_range: float = 160.0

var direction: Vector2 = Vector2.DOWN
var damage: int = 1

var _traveled: float = 0.0
var _hit: bool = false


func _ready() -> void:
	var hurt_box = get_node_or_null("HurtBox")
	if hurt_box == null:
		push_error("[Stone] no HurtBox child found -- check scene structure")
		return
	hurt_box.damage = damage
	body_entered.connect(_on_body_entered)
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	if _hit:
		return
	var step = direction * speed * delta
	global_position += step
	_traveled += step.length()
	if _traveled >= max_range:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	# don't blow up on the player who threw it
	if body is Player:
		return
	queue_free()
