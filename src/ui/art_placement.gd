class_name ArtPlacement
extends RefCounted

## All standing drawings sort at their ground contact, never their image corner.
static func place(sprite: Sprite2D, cell: Vector2i, footprint := Vector2i.ONE) -> void:
	var tile := float(GameData.TILE_SIZE)
	var texture := sprite.texture
	var metadata: Dictionary = RasterArt.FRAMES.get(texture.resource_path, {})
	var pivot: Vector2 = Vector2(metadata.get("pivot",
		Vector2i(texture.get_width() / 2, texture.get_height())))
	sprite.centered = false
	sprite.position = Vector2(cell) * tile + Vector2(float(footprint.x) * tile * 0.5,
		float(footprint.y) * tile)
	sprite.offset = -pivot


static func contact(subtile: Array) -> Vector2:
	var scale := float(GameData.TILE_SIZE) / float(Player.SUBTILE)
	return Vector2(floorf(float(subtile[0]) * scale),
		floorf(float(subtile[1]) * scale) + float(GameData.TILE_SIZE) * 0.5)


## A source-owned lamp/chimney point, or the old logical midpoint for legacy art.
static func emission(id: StringName, corner: Vector2, field: StringName,
		fallback: Vector2) -> Vector2:
	for folder in [WorldView.BUILDING_DIR, WorldView.PROP_DIR]:
		var metadata: Dictionary = RasterArt.FRAMES.get(str(folder) + str(id) + ".png", {})
		if metadata.has(field):
			return corner + Vector2(metadata["cell_offset"]) + Vector2(metadata[field])
	return fallback


## Several measured glass panes belong to one drawing, never its nine cells.
static func emissions(id: StringName, corner: Vector2, field: StringName,
		fallback: Vector2, single_field: StringName = &"light") -> Array[Vector2]:
	var metadata: Dictionary = RasterArt.FRAMES.get(WorldView.BUILDING_DIR + str(id) + ".png", {})
	var points: Array[Vector2] = []
	for point in metadata.get(field, []):
		points.append(corner + Vector2(metadata["cell_offset"]) + Vector2(point))
	if points.is_empty():
		points.append(emission(id, corner, single_field, fallback))
	return points
