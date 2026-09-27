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
## ## Two realities, one set of pixels
##
## `design.md` section 18 asks the player to recognise the farm instantly and
## feel that it is not the same place. So **nothing moves**: the same tiles, the
## same buildings, the same camera - only the light changes, through a
## `CanvasModulate` tinted by `PaletteData`, and a short fade between the two.
##
## The fade is cosmetic all the way down. The simulation never waits for it, and
## skipping it lands in exactly the state watching it would have.
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
	&"workshop": Color8(150, 116, 74),
	&"gun_tower": Color8(120, 130, 160),
	&"wall": Color8(130, 128, 136),
	&"fence": Color8(150, 116, 74),
	&"barricade": Color8(160, 130, 90),
	&"walker": Color8(85, 118, 82),
	&"runner": Color8(120, 140, 80),
	&"tank": Color8(70, 92, 70),
	&"breaker": Color8(110, 80, 70),
	&"giant": Color8(140, 70, 70),
}

## Anything not in the table above, so a new occupant shows up as an obvious
## magenta block rather than as nothing at all.
const UNKNOWN_COLOUR := Color8(220, 60, 200)

## How long the light takes to change. Cosmetic, so it is not in `game_data`:
## a purely visual number in the data hash would mean a balance-neutral tweak
## failed the guard. Task 0078 makes it a setting.
const TRANSITION_SECONDS := 1.1

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

## The build ghost: a half-transparent sprite of what would go down, under a
## frame that is green when it fits and red when it does not.
var _ghost: Sprite2D
var _ghost_frame: Node2D
var _ghost_cell := Vector2i(-1, -1)
var _ghost_ok := false

## The night: everything alive that is not the player, and everything in the
## air. Redrawn every frame rather than on a dirty flag - at night this is the
## thing that is always moving, so a signature check would cost more than the
## redraw it saved.
var _actors: Node2D
var _actor_sprites: Array[Node] = []
var _shots: Node2D

## The light. One node, two colours, and whatever is between them right now.
var _light: CanvasModulate
var _lit_for := -1                  # the phase the fade is heading towards
var _fade := 1.0                    # 0 at the start of a change, 1 when done
var _fade_from := Color.WHITE       # where the fade started


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
	_light = CanvasModulate.new()
	_light.name = "Light"
	_light.color = PaletteData.DAY_TINT
	add_child(_light)

	_plots = Node2D.new()
	_plots.name = "Plots"
	add_child(_plots)
	move_child(_plots, 1)           # after Terrain, before the highlight

	_actors = Node2D.new()
	_actors.name = "Actors"
	_occupants.add_child(_actors)

	_shots = Node2D.new()
	_shots.name = "Shots"
	_shots.z_index = 8              # over everything on the ground
	_shots.draw.connect(_draw_shots)
	add_child(_shots)

	_ghost = Sprite2D.new()
	_ghost.name = "Ghost"
	_ghost.centered = false
	_ghost.visible = false
	_ghost.modulate = Color(1, 1, 1, 0.55)
	_occupants.add_child(_ghost)

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


func _process(delta: float) -> void:
	if _state.is_empty():
		return
	_light_for_phase(delta)
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

	_refresh_actors()
	if _shots != null:
		_shots.queue_redraw()


# -------------------------------------------------------------------- light

## Move the light towards whatever the phase asks for.
##
## PREPARATION counts as night: the sun is down and the first zombie is on its
## way, and a build step lit like an afternoon would be lying about what is
## about to happen.
func _light_for_phase(delta: float) -> void:
	var phase := int(_state["phase"])
	var wants_day := phase == Phases.DAY
	var target: Color = _daylight_now() if wants_day 		else PaletteData.NIGHT_TINT

	if phase != _lit_for:
		# Only a change between the two realities is worth a fade; DAY to DAY
		# after a result screen is not a transition, it is the same light.
		var was_day := _lit_for == Phases.DAY or _lit_for == -1
		_fade = 1.0 if was_day == wants_day else 0.0
		_fade_from = _light.color
		_lit_for = phase

	if _fade >= 1.0:
		# Settled, so it follows the sun rather than sitting on one colour.
		_light.color = target
		return

	# **From where it started, not from where it is.** Lerping the current
	# colour towards the target every frame is an exponential approach: the
	# colour arrives quickly and the progress never quite finishes, which made
	# `is_transitioning()` true long after the fade looked over.
	_fade = minf(_fade + delta / TRANSITION_SECONDS, 1.0)
	_light.color = _fade_from.lerp(target, _fade)


## The colour of the daylight right now: cool at dawn, plain at noon, warm at
## dusk and a little warmer past it.
##
## **A day lit identically from the first tick to the last is a day where time
## is a number in a corner.** `design.md` asks for light that warms and then
## cools, and this is the whole of it - one lerp between three colours the
## palette already generates, costing nothing per sprite because it is a single
## `CanvasModulate`.
##
## It is deliberately gentle. This is the cozy half, and a dawn you have to
## squint through would be a reason to skip the morning.
func _daylight_now() -> Color:
	if _state.is_empty():
		return PaletteData.DAY_TINT
	var through := float(Phases.day_percent(_state)) / 100.0

	# Dawn to noon over the first half, noon to dusk over the second. Past
	# dusk it keeps going towards the evening colour rather than stopping, so
	# a day that runs over looks like one.
	if through <= 0.5:
		return PaletteData.DAWN_TINT.lerp(PaletteData.DAY_TINT,
			clampf(through / 0.5, 0.0, 1.0))
	return PaletteData.DAY_TINT.lerp(PaletteData.DUSK_TINT,
		clampf((through - 0.5) / 0.5, 0.0, 1.0))


## Cut the fade short. The simulation was never waiting for it, so this changes
## what is on screen and nothing else.
func skip_transition() -> void:
	_fade = 1.0


## True while the light is still moving, for task 0078.
func is_transitioning() -> bool:
	return _fade < 1.0


## The colour the light is heading for, whether or not it has got there.
##
## What a test should ask about: whether the fade has finished after N frames
## depends on how busy the machine is, and an assert that depends on that is an
## assert that fails for reasons nobody can act on.
func light_target() -> Color:
	if int(_state.get("phase", Phases.DAY)) != Phases.DAY:
		return PaletteData.NIGHT_TINT
	# **The day's light, at the hour it is.** This returned the noon
	# constant, which was right until task 0039 gave the sun somewhere to
	# travel - after which it was a function that reported where the light
	# used to go rather than where it is going, which is the one thing a
	# test is meant to be able to ask.
	return _daylight_now()


# ------------------------------------------------------------------- camera

## Frame the cell the player would act on, or nothing when there is nothing to
## act on. Called by the screen each frame; redraws only when it moves.
func highlight(cell: Vector2i) -> void:
	if cell == _highlight_cell:
		return
	_highlight_cell = cell
	if _highlight != null:
		_highlight.queue_redraw()


## Put a ghost of `id` on `cell`, framed green when it will go there and red
## when it will not.
## The route the zombies would take if the thing being held went down here.
##
## Drawn as a dotted line over the farm while build mode is up, so the player
## sees what a wall does **before** paying for it. Empty when there is nothing
## to show, which is most of the time: only a thing that blocks the way has a
## route to preview.
var _preview: Array = []


func show_route(cells: Array) -> void:
	if cells == _preview:
		return
	_preview = cells
	if _highlight != null:
		_highlight.queue_redraw()


func clear_route() -> void:
	show_route([])


func previewed_route() -> Array:
	return _preview


func show_ghost(cell: Vector2i, id: StringName, ok: bool) -> void:
	if _ghost == null:
		return
	var size := float(GameData.TILE_SIZE)
	_ghost.texture = _texture_for(id)
	_ghost.position = Vector2(cell) * size
	_ghost.visible = true
	if cell == _ghost_cell and ok == _ghost_ok:
		return
	_ghost_cell = cell
	_ghost_ok = ok
	if _highlight != null:
		_highlight.queue_redraw()


## Whether the ghost is currently saying yes. What the frame colour means, in
## a form a test can ask about - a colour drawn into a canvas is not.
func ghost_is_ok() -> bool:
	return _ghost != null and _ghost.visible and _ghost_ok


func ghost_cell() -> Vector2i:
	return _ghost_cell if _ghost != null and _ghost.visible else Vector2i(-1, -1)


func hide_ghost() -> void:
	if _ghost == null or not _ghost.visible:
		return
	_ghost.visible = false
	_ghost_cell = Vector2i(-1, -1)
	if _highlight != null:
		_highlight.queue_redraw()


func _draw_highlight() -> void:
	# **The route a wall would leave**, dotted so it reads as a prediction
	# rather than as something on the farm.
	if not _preview.is_empty():
		var size := float(GameData.TILE_SIZE)
		var step := 0
		for found in _preview:
			step += 1
			if step % 2 == 0:
				continue
			var cell: Vector2i = found
			_highlight.draw_rect(Rect2(Vector2(cell) * size
				+ Vector2(size, size) * 0.4, Vector2(size, size) * 0.2),
				Color(1.0, 0.85, 0.45, 0.75))

	var size := float(GameData.TILE_SIZE)

	# The build frame first, so that a ghost and an interact target on the same
	# cell both show and the build one is on top.
	if _ghost != null and _ghost.visible and Grid.in_bounds(_ghost_cell):
		var ghost_rect := Rect2(Vector2(_ghost_cell) * size, Vector2(size, size))
		var colour := Color(0.45, 0.95, 0.45, 0.95) if _ghost_ok \
			else Color(0.95, 0.35, 0.35, 0.95)
		_highlight.draw_rect(ghost_rect, colour, false, 1.0)

	if not Grid.in_bounds(_highlight_cell):
		return
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
		var on: Dictionary = occupants[idx]
		var id: StringName = on["id"]
		var cell := Grid.cell(idx)
		var sprite := Sprite2D.new()
		sprite.texture = _texture_for(_art_for(on, cell))
		sprite.centered = false
		sprite.position = Vector2(cell) * float(GameData.TILE_SIZE)
		_occupants.add_child(sprite)
		_sprites.append(sprite)


## Everything alive that is not the player.
##
## Placeholder blocks until task 0074 draws the zombies. They are in the
## y-sorted layer, so one walking past a tree goes behind it.
func _refresh_actors() -> void:
	if _actors == null:
		return
	var ids := Entities.ids(_state)
	# Pool the sprites: a wave is a hundred things moving every frame, and
	# freeing and rebuilding a hundred nodes a frame is the one place this view
	# could plausibly cost something.
	while _actor_sprites.size() < ids.size():
		var sprite := Sprite2D.new()
		sprite.centered = false
		_actors.add_child(sprite)
		_actor_sprites.append(sprite)
	while _actor_sprites.size() > ids.size():
		var spare: Node = _actor_sprites.pop_back()
		spare.queue_free()

	var scale_factor := float(GameData.TILE_SIZE) / float(Player.SUBTILE)
	for i in ids.size():
		var one := Entities.get_one(_state, int(ids[i]))
		var sprite: Sprite2D = _actor_sprites[i]
		sprite.texture = _texture_for(StringName(one["kind"]))
		# **A hit reads at a glance.** The rules say how long something stays
		# lit; the view only turns that into white. Task 0088 adds the shake
		# and the numbers on top.
		sprite.modulate = Color(2.4, 2.2, 2.2) if int(one.get("hurt", 0)) > 0 \
			else Color(1, 1, 1)
		sprite.position = Vector2(
			floorf(float(one["pos"][0]) * scale_factor
				- float(GameData.TILE_SIZE) * 0.5),
			floorf(float(one["pos"][1]) * scale_factor
				- float(GameData.TILE_SIZE) * 0.5))


## Shots in the air. Two pixels of bright, which at this resolution is enough
## to follow a line of fire across the farm.
func _draw_shots() -> void:
	if _state.is_empty():
		return
	var scale_factor := float(GameData.TILE_SIZE) / float(Player.SUBTILE)
	for shot in (_state["projectiles"] as Array):
		var at := Vector2(
			floorf(float(shot["pos"][0]) * scale_factor),
			floorf(float(shot["pos"][1]) * scale_factor))
		_shots.draw_rect(Rect2(at - Vector2.ONE, Vector2(2, 2)),
			PaletteData.COLOURS[&"flame_hot"])


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
		var here: Dictionary = plots[idx]

		# **The earth first, the crop on top of it.** Watering has to stay
		# visible under a crop that is already up - a wet row you cannot see
		# once it has sprouted is a chore with no feedback, and the player would
		# be back to counting which tiles they had done.
		_plot_sprite("tilled_wet" if bool(here["watered"]) else "tilled",
			cell, size)

		var crop: StringName = here["crop"]
		if crop != &"":
			_plot_sprite("%s_%d" % [crop, Farming.stage(_state, cell)],
				cell, size)


## One sprite on one plot. Two of them stack on a watered tile with something
## growing in it, which is why this is a function rather than a block.
func _plot_sprite(art: String, cell: Vector2i, size: float) -> void:
	var texture := _crop_texture(art)
	if texture == null:
		return
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
## Which sprite a cell of an occupant wants.
##
## A one-tile thing wants its own name. A multi-tile one - a press is two by
## two - wants the quarter of itself that this cell is, so the four cells make
## one machine rather than four little machines. `_texture_for` falls back to
## the plain name, so a building whose quarters nobody has drawn yet still
## shows up.
func _art_for(on: Dictionary, cell: Vector2i) -> StringName:
	var at: Variant = on.get("anchor", null)
	if at == null:
		return on["id"]
	var pair: Array = at
	return StringName("%s_%d_%d" % [on["id"], cell.x - int(pair[0]),
		cell.y - int(pair[1])])


func _texture_for(id: StringName) -> Texture2D:
	if _textures.has(id):
		return _textures[id]

	var path := PROP_DIR + str(id) + ".png"
	if ResourceLoader.exists(path):
		var drawn: Texture2D = load(path)
		if drawn != null:
			_textures[id] = drawn
			return drawn

	# A quarter nobody has drawn falls back to the whole thing, and that to a
	# flat block, so a new building is visible before it is pretty.
	var name := str(id)
	var cut := name.rfind("_")
	if cut > 0 and name.substr(cut + 1).is_valid_int():
		var without_row := name.substr(0, cut)
		cut = without_row.rfind("_")
		if cut > 0 and without_row.substr(cut + 1).is_valid_int():
			return _texture_for(StringName(without_row.substr(0, cut)))

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
