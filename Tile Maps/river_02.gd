class_name riverTileMap extends TileMapLayer

func _ready():
	LevelManager.ChangeTilemapBounds(GetTilemapBounds())
	pass
	
func GetTilemapBounds() -> Array[Vector2]:
	var bounds : Array[ Vector2 ] = []
	bounds.append(
		Vector2( get_used_rect().position * rendering_quadrant_size)
	)
	bounds.append(
		Vector2(get_used_rect().end * rendering_quadrant_size)
	)
	return bounds
