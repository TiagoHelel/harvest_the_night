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
	sprite.scale = Vector2.ONE * visual_scale(texture.resource_path)


## Doors and furniture-sized production buildings now match the 30px farmer.
## Integer scaling preserves the already accepted exterior raster sheets.
static func visual_scale(path: String) -> float:
	if (path.begins_with("res://sprites/buildings/") or path.begins_with("res://sprites/props/")) \
		and path.get_file().split("_")[0].get_basename() \
			in ["house", "shop", "workshop", "kitchen", "press", "generator"]:
		return 2.0
	return 1.0


static func contact(subtile: Array) -> Vector2:
	var scale := float(GameData.TILE_SIZE) / float(Player.SUBTILE)
	return Vector2(floorf(float(subtile[0]) * scale),
		floorf(float(subtile[1]) * scale) + float(GameData.TILE_SIZE) * 0.5)


## A source-owned lamp/chimney point, or the old logical midpoint for legacy art.
static func emission(id: StringName, corner: Vector2, field: StringName,
		fallback: Vector2, footprint := Vector2i.ZERO) -> Vector2:
	for folder in [WorldView.BUILDING_DIR, WorldView.PROP_DIR]:
		var metadata: Dictionary = RasterArt.FRAMES.get(str(folder) + str(id) + ".png", {})
		if metadata.has(field):
			var scale := visual_scale(str(folder) + str(id) + ".png")
			if scale == 1.0:
				return corner + Vector2(metadata["cell_offset"]) + Vector2(metadata[field])
			var size := Building.size_of(id) if footprint == Vector2i.ZERO else footprint
			var contact := Vector2(float(size.x) * GameData.TILE_SIZE * 0.5, size.y * GameData.TILE_SIZE)
			return corner + contact + (Vector2(metadata[field]) - Vector2(metadata["pivot"])) * scale
	return fallback


## Several measured glass panes belong to one drawing, never its nine cells.
static func emissions(id: StringName, corner: Vector2, field: StringName,
		fallback: Vector2, single_field: StringName = &"light", footprint := Vector2i.ZERO) -> Array[Vector2]:
	var metadata: Dictionary = RasterArt.FRAMES.get(WorldView.BUILDING_DIR + str(id) + ".png", {})
	var points: Array[Vector2] = []
	for point in metadata.get(field, []):
		var scale := visual_scale(WorldView.BUILDING_DIR + str(id) + ".png")
		if scale == 1.0:
			points.append(corner + Vector2(metadata["cell_offset"]) + Vector2(point))
		else:
			var size := Building.size_of(id) if footprint == Vector2i.ZERO else footprint
			points.append(corner + Vector2(float(size.x) * GameData.TILE_SIZE * 0.5, size.y * GameData.TILE_SIZE)
				+ (Vector2(point) - Vector2(metadata["pivot"])) * scale)
	if points.is_empty():
		points.append(emission(id, corner, single_field, fallback, footprint))
	return points
