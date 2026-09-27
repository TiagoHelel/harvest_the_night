class_name WorldView
extends Node2D

## The farm, on screen.
##
## **It reads the core state and never writes to it.** Everything here is a
## consequence of `Farm`; if the view and the rules ever disagree, the view is
## wrong. That is what lets the headless tools and the autoplayer play the same
## game with no window at all.
##
## Two layers, because they sort differently. Terrain is a `TileMapLayer` - flat,
## built once, never touched again, because terrain does not change. Occupants
## and actors go on a y-sorted `Node2D` above it, so a tree drawn at the bottom
## of the screen is in front of a tower drawn above it, which is what makes a
## three-quarter view read as depth rather than as a spreadsheet.
##
## ## Where the art comes from
##
## `sprites/`, generated from the ASCII maps in `tools/sprite_maps.py` by
## `tools/gen_sprites.py`. **Nothing here paints anything.** An occupant that
## the pipeline has not drawn yet falls back to a flat block in the colour
## table below - deliberately visible, so "nobody has drawn the house" looks
## like a placeholder rather than like a design choice. Task 0075 draws them.

## The farm is 640x288 pixels and the viewport is 480x270, so there are 160
## pixels of horizontal pan and 18 of vertical.
##
## **Vertically the camera is locked to the middle**, which crops nine pixels
## off the top and the bottom. That is deliberate and the map is drawn for it:
## row 0 and row 17 are the tree line and the far water, a decorative border
## rather than anywhere the player goes. A camera that drifted up and down over
## eighteen pixels would be motion sickness in exchange for nothing.
const WORLD_SIZE := Vector2i(
	GameData.GRID_WIDTH * GameData.TILE_SIZE,
	GameData.GRID_HEIGHT * GameData.TILE_SIZE)

## Placeholder terrain colours, in `Farm.Terrain` order.
const TERRAIN_COLOURS: Array = [
	Color8(106, 150, 70),       # GRASS
	Color8(122, 88, 56),        # SOIL
	Color8(58, 110, 165),       # WATER
	Color8(110, 108, 120),      # ROCK
	Color8(168, 143, 102),      # PATH
	Color8(140, 100, 60),       # FLOOR
]

## Fallback colours, for occupants the sprite pipeline has not drawn yet.
##
## Chosen for **contrast against what they stand on**, not for beauty: an early
## render had trees at a green close to the grass in value and they vanished
## into the lawn. Anything with a PNG in `sprites/props/` ignores this table.
const OCCUPANT_COLOURS: Dictionary = {
	&"tree": Color8(24, 58, 32),
	&"stump": Color8(96, 70, 44),
	&"rock": Color8(150, 148, 158),
	&"ore": Color8(196, 150, 70),
	&"seam": Color8(120, 118, 130),
	&"house": Color8(176, 66, 58),
	&"shop": Color8(214, 186, 96),
	&"gun_tower": Color8(120, 130, 160),
	&"wall": Color8(130, 128, 136),
	&"fence": Color8(150, 116, 74),
	&"barricade": Color8(160, 130, 90),
}

## Anything not in the table above, so a new occupant shows up as an obvious
## magenta block rather than as nothing at all.
const UNKNOWN_COLOUR := Color8(220, 60, 200)

@onready var _terrain: TileMapLayer = $Terrain
@onready var _occupants: Node2D = $Occupants
@onready var _camera: Camera2D = $Camera

var _state: Dictionary = {}
var _dirty := true
var _last_signature := 0
var _textures: Dictionary = {}

## The sprites this view created, so that `_refresh()` can clear them without
## also destroying the player, who lives in the same y-sorted layer in order to
## sort against the trees.
var _sprites: Array[Node] = []

## A frame around the cell the player would act on, drawn over the terrain and
## under everything standing on it. Task 0023 reuses it for the build ghost.
var _highlight: Node2D
var _highlight_cell := Vector2i(-1, -1)

## The field: turned earth and whatever is growing in it. Flat on the ground
## rather than standing on it, because a crop is not something you walk around
## - and at night it is ground to defend, not furniture.
var _plots: Node2D
var _plot_sprites: Array[Node] = []
var _plots_signature := 0


func _ready() -> void:
	_terrain.tile_set = _build_terrain_tileset()

	# Camera limits are the farm's edges, so panning can never show a gap or a
	# repeated column - the engine does the clamping and no arithmetic here can
	# get it wrong.
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = WORLD_SIZE.x
	_camera.limit_bottom = WORLD_SIZE.y
	_camera.position_smoothing_enabled = false      # pixel art: no half pixels
	_camera.ignore_rotation = true
	_camera.make_current()
	_camera.position = Vector2(WORLD_SIZE) * 0.5

	# **Its own node between the terrain and the actors**, rather than a
	# negative z_index inside the sorted layer. Negative z inside a Y-sorted
	# parent put it behind the TileMapLayer, so the frame was drawn under the
	# grass and nothing appeared on screen at all.
	_plots = Node2D.new()
	_plots.name = "Plots"
	add_child(_plots)
	move_child(_plots, 1)           # after Terrain, before the highlight

	_highlight = Node2D.new()
	_highlight.name = "Highlight"
	_highlight.draw.connect(_draw_highlight)
	add_child(_highlight)
	move_child(_highlight, 1)       # after Terrain, before Occupants


## Point the view at a game. Called by whatever screen owns the simulation.
func show_state(state: Dictionary) -> void:
	_state = state
	_dirty = true
	_draw_terrain()
	_refresh()
	_refresh_plots()


## Redraw the occupants next frame. Called by anything that knows it changed
## the farm; the signature check below catches the rest.
func mark_dirty() -> void:
	_dirty = true


func _process(_delta: float) -> void:
	if _state.is_empty():
		return
	# **Not rebuilt every frame.** Godot's Dictionary hash is cheap and exact
	# enough to notice a placement or a removal; the determinism hash is a
	# different thing for a different job and is not used here.
	var signature: int = (_state["occupants"] as Dictionary).hash()
	if signature != _last_signature:
		_last_signature = signature
		_dirty = true
	if _dirty:
		_dirty = false
		_refresh()

	var plots: int = (_state["plots"] as Dictionary).hash()
	if plots != _plots_signature:
		_plots_signature = plots
		_refresh_plots()


# ------------------------------------------------------------------- camera

## Frame the cell the player would act on, or nothing when there is nothing to
## act on. Called by the screen each frame; redraws only when it moves.
func highlight(cell: Vector2i) -> void:
	if cell == _highlight_cell:
		return
	_highlight_cell = cell
	if _highlight != null:
		_highlight.queue_redraw()


func _draw_highlight() -> void:
	if not Grid.in_bounds(_highlight_cell):
		return
	var size := float(GameData.TILE_SIZE)
	var rect := Rect2(Vector2(_highlight_cell) * size, Vector2(size, size))
	# A frame rather than a fill: the player needs to see what is on the tile
	# as well as that it is selected.
	_highlight.draw_rect(rect, Color(1.0, 0.98, 0.85, 0.85), false, 1.0)
	_highlight.draw_rect(rect.grow(-1.0), Color(0.0, 0.0, 0.0, 0.25), false, 1.0)


## Keep the camera on a cell, clamped to the farm and locked vertically.
func look_at_cell(cell: Vector2i) -> void:
	_camera.position.x = float(cell.x * GameData.TILE_SIZE + GameData.TILE_SIZE / 2)
	_camera.position.y = float(WORLD_SIZE.y) * 0.5


## Where a farm cell is on screen, in viewport pixels.
##
## `input_check` asks for this by name so that a click on a cell goes wherever
## the camera has put it, rather than wherever it would have been if the camera
## had never moved.
func cell_to_screen(cell: Vector2i) -> Vector2:
	var local := Vector2(cell) * float(GameData.TILE_SIZE) \
		+ Vector2.ONE * (float(GameData.TILE_SIZE) * 0.5)
	return get_global_transform_with_canvas() * local


## Which cell a screen position is over, or (-1, -1) when it is off the farm.
func screen_to_cell(position: Vector2) -> Vector2i:
	var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * position
	var cell := Vector2i((local / float(GameData.TILE_SIZE)).floor())
	return cell if Grid.in_bounds(cell) else Vector2i(-1, -1)


# -------------------------------------------------------------------- drawing

## Terrain is built once. It cannot change: nothing in the game turns grass
## into water, and the day and the night are the same tiles by design.
func _draw_terrain() -> void:
	if _state.is_empty():
		return
	_terrain.clear()
	var bytes: PackedByteArray = _state["terrain"]
	for idx in Grid.CELLS:
		var cell := Grid.cell(idx)
		_terrain.set_cell(cell, 0, Vector2i(int(bytes[idx]), 0))


func _refresh() -> void:
	for sprite in _sprites:
		sprite.queue_free()
	_sprites.clear()
	if _state.is_empty():
		return

	var occupants: Dictionary = _state["occupants"]
	# Sorted, so that two runs build the same tree in the same order. Nothing
	# depends on it yet; the day something here draws from the RNG, it will.
	var keys: Array = occupants.keys()
	keys.sort()
	for idx in keys:
		var id: StringName = (occupants[idx] as Dictionary)["id"]
		var cell := Grid.cell(idx)
		var sprite := Sprite2D.new()
		sprite.texture = _texture_for(id)
		sprite.centered = false
		sprite.position = Vector2(cell) * float(GameData.TILE_SIZE)
		_occupants.add_child(sprite)
		_sprites.append(sprite)


## Turned earth, and the crop on it at whatever stage it has reached.
func _refresh_plots() -> void:
	for sprite in _plot_sprites:
		sprite.queue_free()
	_plot_sprites.clear()
	if _state.is_empty() or _plots == null:
		return

	var size := float(GameData.TILE_SIZE)
	var plots: Dictionary = _state["plots"]
	var keys: Array = plots.keys()
	keys.sort()
	for idx in keys:
		var cell := Grid.cell(int(idx))
		var crop: StringName = (plots[idx] as Dictionary)["crop"]
		var art := "tilled" if crop == &"" \
			else "%s_%d" % [crop, Farming.stage(_state, cell)]
		var texture := _crop_texture(art)
		if texture == null:
			continue
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.position = Vector2(cell) * size
		_plots.add_child(sprite)
		_plot_sprites.append(sprite)


## A crop sprite, cached. A stage the pipeline has not drawn falls back to the
## turned earth rather than to nothing, so a missing frame looks like a missing
## frame instead of like a field that stopped growing.
func _crop_texture(art: String) -> Texture2D:
	var key := StringName("crop/" + art)
	if _textures.has(key):
		return _textures[key]
	var path := CROP_DIR + art + ".png"
	if not ResourceLoader.exists(path):
		push_warning("no crop sprite at %s" % path)
		path = CROP_DIR + "tilled.png"
		if not ResourceLoader.exists(path):
			return null
	var texture: Texture2D = load(path)
	_textures[key] = texture
	return texture


# ----------------------------------------------------------------- the art

## The terrain atlas: six tiles in a strip, in `Farm.Terrain` order, generated
## by `tools/gen_sprites.py` from `tools/sprite_maps.py`.
const TERRAIN_ATLAS := "res://sprites/terrain/atlas.png"
const PROP_DIR := "res://sprites/props/"
const CROP_DIR := "res://sprites/crops/"


func _build_terrain_tileset() -> TileSet:
	var size := GameData.TILE_SIZE
	var texture: Texture2D = load(TERRAIN_ATLAS)
	if texture == null:
		push_error("no terrain atlas at %s - run: python tools/gen_sprites.py"
			% TERRAIN_ATLAS)
		texture = _flat_atlas()

	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(size, size)
	for t in TERRAIN_COLOURS.size():
		source.create_tile(Vector2i(t, 0))

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(size, size)
	tile_set.add_source(source, 0)
	return tile_set


## A drawn sprite when the pipeline has one, and an obvious flat block when it
## does not. Cached, because this is called once per occupant per redraw.
func _texture_for(id: StringName) -> Texture2D:
	if _textures.has(id):
		return _textures[id]

	var path := PROP_DIR + str(id) + ".png"
	if ResourceLoader.exists(path):
		var drawn: Texture2D = load(path)
		if drawn != null:
			_textures[id] = drawn
			return drawn

	return _flat_block(id)


## The fallback. Task 0075 makes this unreachable.
func _flat_block(id: StringName) -> Texture2D:
	var size := GameData.TILE_SIZE
	var colour: Color = OCCUPANT_COLOURS.get(id, UNKNOWN_COLOUR)
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	# Inset by one pixel so the terrain still shows around the edge, with a
	# darker rim so a block reads as an object rather than as a stain on the
	# grass.
	var rim := Color(colour.r * 0.55, colour.g * 0.55, colour.b * 0.55)
	for y in size:
		for x in size:
			var edge := x <= 1 or y <= 1 or x >= size - 2 or y >= size - 2
			var outside := x == 0 or y == 0 or x == size - 1 or y == size - 1
			image.set_pixel(x, y,
				Color(0, 0, 0, 0) if outside else (rim if edge else colour))
	var tex := ImageTexture.create_from_image(image)
	_textures[id] = tex
	return tex


## Only reached when the atlas is missing, so that a forgotten generator step
## is a loud error plus a playable farm rather than a black screen.
func _flat_atlas() -> Texture2D:
	var size := GameData.TILE_SIZE
	var image := Image.create(size * TERRAIN_COLOURS.size(), size, false,
		Image.FORMAT_RGBA8)
	for t in TERRAIN_COLOURS.size():
		for y in size:
			for x in size:
				image.set_pixel(t * size + x, y, TERRAIN_COLOURS[t])
	return ImageTexture.create_from_image(image)
