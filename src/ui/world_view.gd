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
## **A cap, so nothing can shake the screen to pieces.** Six pixels is a
## fortieth of a 270-pixel screen: enough to feel, small enough that the farm
## never stops being readable. A mortar landing on eight zombies asks for far
## more than this and gets six.
const SHAKE_CAP := 6.0

## How fast a shake dies away, as a fraction of itself a second.
const SHAKE_DECAY := 9.0

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

## How long the light takes to change, when nothing says otherwise. Task
## 0078 moved the number itself to `GameData.TRANSITION_SECONDS` - a lever, so
## a designer can turn it - and left it out of `digest()`, so turning it does
## not fail a guard that watches balance. `video/transition_seconds` overrides
## it for a player who has seen the moment enough times.
var _transition_seconds := GameData.TRANSITION_SECONDS

## How hard the camera is shaking, in pixels, and how fast that dies away.
## Its own generator, so that seeding the globals for a screenshot does not
## decide which way the screen jumps.
var _shake := 0.0
var _shake_rng := RandomNumberGenerator.new()

@onready var _terrain: TileMapLayer = $Terrain
## The edges, on their own layer over the terrain. A cell can only hold one
## tile, and an edge has to be able to sit on top of the tile it softens.
var _edges: TileMapLayer
## Independent caps allow simultaneous diagonal joins on one cell.
var _corners: Array[TileMapLayer] = []
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
var _ghost_id: StringName = &""

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
## The rest of the ramp. A sibling layer, so it can sit over the whole world
## and under the whole HUD; null when the view is opened on its own.
var _relight: Relight


func _ready() -> void:
	_terrain.tile_set = _build_terrain_tileset()

	_edges = TileMapLayer.new()
	_edges.name = "TerrainEdges"
	_edges.tile_set = _terrain.tile_set
	add_child(_edges)
	move_child(_edges, 1)           # directly over the terrain
	for corner in 4:
		var layer := TileMapLayer.new()
		layer.name = "TerrainCorner%d" % corner
		layer.tile_set = _terrain.tile_set
		add_child(layer)
		move_child(layer, 2 + corner)
		_corners.append(layer)

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
	# **Found, not made.** The relight layer is a sibling in `Main.tscn`
	# rather than a child here, because it must sit above the whole world and
	# below the whole HUD - which is a fact about the scene, not about the
	# view. A `WorldView` opened on its own simply has no relight and draws in
	# the palette's own colours, which is what a sprite check wants anyway.
	_read_transition_length()
	_relight = get_tree().root.find_child("Relight", true, false) as Relight

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
	_actors.y_sort_enabled = true
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
	_shake_camera(delta)
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
		_wear(_ramp_now())
		return

	# **From where it started, not from where it is.** Lerping the current
	# colour towards the target every frame is an exponential approach: the
	# colour arrives quickly and the progress never quite finishes, which made
	# `is_transitioning()` true long after the fade looked over.
	_fade = minf(_fade + delta / maxf(_transition_seconds, 0.05), 1.0)
	_light.color = _fade_from.lerp(target, _fade)
	_wear(_blend(_ramp_of(_fade_from), _ramp_now(), _fade))


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


## What the light is made of right now: the tint, and the three things a
## multiply cannot do.
##
## **The ramp is computed, not deduced from the tint.** The first version
## worked out how far into the night the light was by looking at how much more
## blue than green its tint was - which is true of the night ramp and *also*
## true of dawn, because dawn is a cool light. So a farm at seven in the
## morning was being drained to 90% saturation and lifted towards purple, on
## the strength of a colour that meant "early" rather than "dark". Measured at
## 0.28 of the way into the night, at dawn, on the first screenshot taken.
##
## Asking the phase and the hour is both simpler and correct, and it is the
## same question `_daylight_now()` was already answering for the tint.
func _ramp_now() -> Dictionary:
	if _state.is_empty() or int(_state.get("phase", Phases.DAY)) != Phases.DAY:
		return _night_ramp()
	var through := float(Phases.day_percent(_state)) / 100.0
	if through <= 0.5:
		return _blend(_dawn_ramp(), _day_ramp(),
			clampf(through / 0.5, 0.0, 1.0))
	return _blend(_day_ramp(), _dusk_ramp(),
		clampf((through - 0.5) / 0.5, 0.0, 1.0))


## The ramp a given tint belongs to, for the far end of a fade. Only ever
## asked about a colour the light was actually on, which is one of the four.
func _ramp_of(tint: Color) -> Dictionary:
	for ramp in [_night_ramp(), _dawn_ramp(), _day_ramp(), _dusk_ramp()]:
		if (ramp["tint"] as Color).is_equal_approx(tint):
			return ramp
	# Mid-fade when something interrupted: the day is the safe answer, since
	# the only thing this changes is one frame of a transition.
	var out := _day_ramp()
	out["tint"] = tint
	return out


static func _day_ramp() -> Dictionary:
	return {"tint": PaletteData.DAY_TINT, "lift": PaletteData.DAY_LIFT,
		"saturation": PaletteData.DAY_SATURATION,
		"warm_keep": PaletteData.DAY_WARM_KEEP,
		"warm_edge": PaletteData.DAY_WARM_EDGE}


static func _dawn_ramp() -> Dictionary:
	return {"tint": PaletteData.DAWN_TINT, "lift": PaletteData.DAWN_LIFT,
		"saturation": PaletteData.DAWN_SATURATION,
		"warm_keep": PaletteData.DAWN_WARM_KEEP,
		"warm_edge": PaletteData.DAWN_WARM_EDGE}


static func _dusk_ramp() -> Dictionary:
	return {"tint": PaletteData.DUSK_TINT, "lift": PaletteData.DUSK_LIFT,
		"saturation": PaletteData.DUSK_SATURATION,
		"warm_keep": PaletteData.DUSK_WARM_KEEP,
		"warm_edge": PaletteData.DUSK_WARM_EDGE}


static func _night_ramp() -> Dictionary:
	return {"tint": PaletteData.NIGHT_TINT, "lift": PaletteData.NIGHT_LIFT,
		"saturation": PaletteData.NIGHT_SATURATION,
		"warm_keep": PaletteData.NIGHT_WARM_KEEP,
		"warm_edge": PaletteData.NIGHT_WARM_EDGE}


## One ramp on the way to another. Every field travels together, so a light
## halfway between the day and the night is halfway in all four of them.
static func _blend(from: Dictionary, to: Dictionary, t: float) -> Dictionary:
	var at := clampf(t, 0.0, 1.0)
	return {
		"tint": (from["tint"] as Color).lerp(to["tint"], at),
		"lift": (from["lift"] as Color).lerp(to["lift"], at),
		"saturation": lerpf(from["saturation"], to["saturation"], at),
		"warm_keep": lerpf(from["warm_keep"], to["warm_keep"], at),
		"warm_edge": lerpf(from["warm_edge"], to["warm_edge"], at),
	}


## Put a ramp on. The tint goes on the `CanvasModulate`, which the rest of the
## game reads; the other three go to the shader, which is the only thing that
## can apply them.
func _wear(ramp: Dictionary) -> void:
	if _relight == null:
		return
	_relight.apply(_light.color, ramp["lift"], ramp["saturation"],
		ramp["warm_keep"], ramp["warm_edge"])


## The ramp the light is heading for, for `input_check` to read back.
func ramp_target() -> Dictionary:
	return _ramp_now()


## Cut the fade short. The simulation was never waiting for it, so this changes
## what is on screen and nothing else.
func skip_transition() -> void:
	_fade = 1.0


## True while the light is still moving, for task 0078.
func is_transitioning() -> bool:
	return _fade < 1.0


## How far through the change the world is, 0 at the start and 1 when it is
## over. What `Transition` hangs its theatre on.
func transition_progress() -> float:
	return clampf(_fade, 0.0, 1.0)


## Whether the world is on its way *into* the night, as opposed to out of it.
## The morning is the reward half and does not look the same.
func going_dark() -> bool:
	return _lit_for != Phases.DAY


## The length, read once, by path - `verify.py` parses every script on its own
## with no autoload registered.
func _read_transition_length() -> void:
	var service := get_node_or_null("/root/Settings")
	if service == null or not service.has_method("get_value"):
		return
	var seconds: Variant = service.get_value(&"video/transition_seconds")
	if seconds != null and float(seconds) > 0.0:
		_transition_seconds = float(seconds)
	var skip: Variant = service.get_value(&"gameplay/skip_transition")
	if skip != null and bool(skip):
		# A player who has turned the moment off gets the shortest change
		# the code can draw rather than a special case that never fades.
		_transition_seconds = 0.05


## For `input_check`, and for `Transition` to report honestly.
func transition_seconds() -> float:
	return _transition_seconds


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
	ArtPlacement.place(_ghost, cell, Vector2i(3, 3) if id == &"house" else Building.size_of(id))
	_ghost.visible = true
	if cell == _ghost_cell and ok == _ghost_ok and id == _ghost_id:
		return
	_ghost_cell = cell
	_ghost_ok = ok
	_ghost_id = id
	if _highlight != null:
		_highlight.queue_redraw()


## Whether the ghost is currently saying yes. What the frame colour means, in
## a form a test can ask about - a colour drawn into a canvas is not.
func ghost_is_ok() -> bool:
	return _ghost != null and _ghost.visible and _ghost_ok


func ghost_cell() -> Vector2i:
	return _ghost_cell if _ghost != null and _ghost.visible else Vector2i(-1, -1)


func ghost_footprint() -> Vector2i:
	return Vector2i(3, 3) if _ghost_id == &"house" else Building.size_of(_ghost_id)


func hide_ghost() -> void:
	if _ghost == null or not _ghost.visible:
		return
	_ghost.visible = false
	_ghost_cell = Vector2i(-1, -1)
	if _highlight != null:
		_highlight.queue_redraw()


func _draw_highlight() -> void:
	if _state.is_empty():
		return
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

	# **What the Giant is about to hit.** A ring closing on the cell it has
	# picked, so the second the telegraph buys is a second the player can see
	# and spend. Drawn from the rules' own wind-up, so it cannot promise a
	# blow that is not coming.
	for id in Entities.ids(_state):
		var aimed := Enemies.winding_at(_state, id)
		if aimed.x < 0:
			continue
		var middle := (Vector2(aimed) + Vector2(0.5, 0.5)) * size
		var swing := fmod(float(Time.get_ticks_msec()) / 400.0, 1.0)
		_highlight.draw_arc(middle, size * (1.4 - 0.6 * swing), 0.0, TAU, 24,
			Color(1.0, 0.45, 0.30, 0.9), 2.0, true)

	# **The flare.** An expanding ring at the player's feet, fading as it goes,
	# so the one button reads as something that happened *there* rather than a
	# number changing in a corner.
	#
	# Drawn entirely from what the rules already recorded - where it went off
	# and how many ticks are left - so there is nothing for the view to
	# remember and nothing here that could disagree with the damage.
	var burst := Ability.flare_at(_state)
	if not burst.is_empty():
		var full := maxf(float(GameData.ABILITY["flare_ticks"]), 1.0)
		var left := float(Ability.flare_ticks(_state))
		var grown := 1.0 - left / full          # 0 at the bang, 1 at the end
		var reach := float(int(GameData.ABILITY["radius_tiles"])) + 0.5
		var middle := (Vector2(float(burst[0]), float(burst[1]))
			+ Vector2(0.5, 0.5)) * size
		_highlight.draw_arc(middle, reach * size * grown, 0.0, TAU, 40,
			Color(1.0, 0.86, 0.42, 0.9 * left / full), 2.0, true)
		_highlight.draw_circle(middle, reach * size * grown,
			Color(1.0, 0.78, 0.35, 0.22 * left / full))

	# The build frame first, so that a ghost and an interact target on the same
	# cell both show and the build one is on top.
	if _ghost != null and _ghost.visible and Grid.in_bounds(_ghost_cell):
		var footprint := ghost_footprint()
		var ghost_rect := Rect2(Vector2(_ghost_cell) * size, Vector2(footprint) * size)
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
## Shake the camera by this much, in pixels.
##
## **The camera and not the world.** `Camera2D.offset` moves what is drawn
## without moving where the camera *is*, so `Main` can keep pointing it at
## the farmer every frame - and the UI, which is on its own `CanvasLayer`,
## does not move at all. A HUD that shook with the screen would be a HUD you
## could not read at the moment you most needed to.
##
## Asking again keeps the bigger of the two: six zombies dying together is
## one shake, not six added up into a screen nobody can look at.
func shake(pixels: float) -> void:
	_shake = maxf(_shake, pixels)


func shake_amount() -> float:
	return _shake


## A new offset every frame while it lasts, dying away exponentially.
##
## **Scaled by `a11y/screen_shake` and gone entirely at zero.** A player who
## has turned it off gets a camera that never moves - not a smaller shake -
## which is what the setting promises and what somebody prone to motion
## sickness needs it to mean.
func _shake_camera(delta: float) -> void:
	if _shake <= 0.0:
		if _camera != null and _camera.offset != Vector2.ZERO:
			_camera.offset = Vector2.ZERO
		return
	_shake = maxf(_shake - _shake * SHAKE_DECAY * delta, 0.0)
	if _shake < 0.05:
		_shake = 0.0
	var scale := _shake_setting()
	if _camera == null:
		return
	if scale <= 0.0:
		_camera.offset = Vector2.ZERO
		return
	var amount := minf(_shake, SHAKE_CAP) * scale
	_camera.offset = Vector2(
		_shake_rng.randf_range(-amount, amount),
		_shake_rng.randf_range(-amount, amount)).round()


func _shake_setting() -> float:
	var service := get_node_or_null(^"/root/Settings")
	if service == null:
		return 1.0
	return clampf(float(service.get_float(&"a11y/screen_shake")), 0.0, 2.0)


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
##
## Two passes, because the second needs the first to exist: the base tile is a
## function of one cell, and the edge is a function of a cell and its four
## neighbours.
func _draw_terrain() -> void:
	if _state.is_empty():
		return
	_terrain.clear()
	if _edges != null:
		_edges.clear()
	for layer in _corners:
		layer.clear()
	var bytes: PackedByteArray = _state["terrain"]
	for idx in Grid.CELLS:
		var cell := Grid.cell(idx)
		_terrain.set_cell(cell, 0, _base_tile(int(bytes[idx]), cell))
	if _edges == null:
		return
	for idx in Grid.CELLS:
		var cell := Grid.cell(idx)
		var at := _edge_tile(bytes, cell, int(bytes[idx]))
		if at.x >= 0:
			_edges.set_cell(cell, 0, at)
		var corners := _corner_mask(bytes, cell, int(bytes[idx]))
		var start := CORNER_SHORE_START if int(bytes[idx]) == Farm.Terrain.WATER else CORNER_EDGE_START
		for corner in 4:
			if corners & (1 << corner):
				_corners[corner].set_cell(cell, 0, Vector2i(start + corner, ROW_BASE))


## The tile a cell of this terrain shows.
##
## Static, along with `_grass_variant()` and `_edge_tile()`, because all three
## are functions of a cell and the terrain around it and of nothing else - no
## node, no state, no frame. That makes them the kind of thing a headless
## check can call directly, which is where the rules below are asserted.
##
## Grass gets one of four, picked off the cell's own coordinates so that the
## field is the same field every time it is drawn and on every machine. Water
## gets the animated one, which lives on its own row because Godot takes an
## animation's frames from the tiles to its right - and to the right of the
## water in row 0 is the rock.
static func _base_tile(terrain: int, cell: Vector2i) -> Vector2i:
	if terrain == Farm.Terrain.WATER:
		return Vector2i(0, ROW_WATER)
	if terrain == Farm.Terrain.GRASS:
		return Vector2i(_grass_variant(cell), ROW_GRASS)
	return Vector2i(terrain, ROW_BASE)


## Which of the four grasses this cell is.
##
## Weighted quiet source-owned clusters: the plain tile takes more than half,
## and the rare grass variation turns up about once in thirty cells. Decorative
## variations never change the terrain byte or the cell's walkability.
static func _grass_variant(cell: Vector2i) -> int:
	var h := (cell.x * 73856093) ^ (cell.y * 19349663)
	match absi(h) % 32:
		31:
			return 3
		25, 26, 27, 28, 29, 30:
			return 2
		18, 19, 20, 21, 22, 23, 24:
			return 1
		_:
			return 0


## The edge tile that softens this cell, or (-1, -1) for none.
##
## **Two rules, and they cannot both fire on one cell.** Water draws its own
## pale bank wherever it meets anything that is not water. Everything that is
## neither grass nor water draws grass encroaching into it wherever grass is
## next door. Grass itself draws nothing: it is the background the rest is cut
## out of, so softening the patch is the same job as softening the meadow and
## half the tiles.
static func _edge_tile(bytes: PackedByteArray, cell: Vector2i,
		terrain: int) -> Vector2i:
	if terrain == Farm.Terrain.GRASS:
		return Vector2i(-1, -1)
	var row := ROW_SHORE if terrain == Farm.Terrain.WATER else ROW_EDGE
	var mask := 0
	for bit in EDGE_NEIGHBOURS.size():
		var at: Vector2i = cell + EDGE_NEIGHBOURS[bit]
		if not Grid.in_bounds(at):
			continue        # the map's border is not an edge of anything
		var theirs := int(bytes[Grid.index(at)])
		var edged := theirs != Farm.Terrain.WATER \
			if terrain == Farm.Terrain.WATER \
			else theirs == Farm.Terrain.GRASS
		if edged:
			mask |= 1 << bit
	return Vector2i(-1, -1) if mask == 0 else Vector2i(mask, row)


## A diagonal cap fills only an exposed elbow: neither adjoining cardinal
## side can already draw an edge. It reads terrain without changing any state.
static func _corner_mask(bytes: PackedByteArray, cell: Vector2i, terrain: int) -> int:
	if terrain == Farm.Terrain.GRASS:
		return 0
	var at := _edge_tile(bytes, cell, terrain)
	var cardinal := maxi(0, at.x)
	var mask := 0
	for corner in 4:
		if cardinal & CORNER_CARDINALS[corner]:
			continue
		var diagonal: Vector2i = cell + CORNER_NEIGHBOURS[corner]
		if not Grid.in_bounds(diagonal):
			continue
		var theirs := int(bytes[Grid.index(diagonal)])
		var touches := theirs != Farm.Terrain.WATER if terrain == Farm.Terrain.WATER else theirs == Farm.Terrain.GRASS
		if touches:
			mask |= 1 << corner
	return mask


func _refresh() -> void:
	for sprite in _sprites:
		sprite.queue_free()
	_sprites.clear()
	_find_fixture_corners()
	if _state.is_empty():
		return

	var occupants: Dictionary = _state["occupants"]
	# Sorted, so that two runs build the same tree in the same order. Nothing
	# depends on it yet; the day something here draws from the RNG, it will.
	# Cell indices, so these are integers and sort as integers.
	var keys: Array = occupants.keys()
	keys.sort()
	for idx in keys:
		var on: Dictionary = occupants[idx]
		var id: StringName = on["id"]
		var cell := Grid.cell(idx)
		var anchor := cell
		var anchored: Variant = on.get("anchor", null)
		if anchored != null:
			anchor = Vector2i(int(anchored[0]), int(anchored[1]))
		elif _fixture_corner.has(id):
			anchor = _fixture_corner[id]
		var footprint := Vector2i(3, 3) if id == &"house" else Building.size_of(id)
		var whole := _texture_for(_worn(id, on))
		var grouped := footprint != Vector2i.ONE and (RasterArt.FRAMES.has(whole.resource_path)
			or (whole.get_width() >= footprint.x * GameData.TILE_SIZE
			and whole.get_height() >= footprint.y * GameData.TILE_SIZE))
		if grouped and cell != anchor:
			continue
		var sprite := Sprite2D.new()
		sprite.name = "Prop_%d" % idx
		sprite.texture = whole if grouped else _texture_for(_art_for(on, cell))
		ArtPlacement.place(sprite, anchor if grouped else cell, footprint if grouped else Vector2i.ONE)
		var logical_cells: Array = []
		if grouped:
			for y in footprint.y:
				for x in footprint.x:
					logical_cells.append(Grid.index(anchor + Vector2i(x, y)))
		else:
			logical_cells.append(idx)
		sprite.set_meta("logical_cells", logical_cells)
		if id == &"tree":
			var shadow := Sprite2D.new()
			shadow.texture = load(PlayerView.SHADOW)
			shadow.position.y = -1.0
			shadow.modulate.a = PlayerView.SHADOW_ALPHA
			shadow.show_behind_parent = true
			sprite.add_child(shadow)
		_occupants.add_child(sprite)
		_sprites.append(sprite)
		# **One pip a level, above the tower.** The art for a Torre II does
		# not exist yet and this does not wait for it: a player has to be
		# able to tell at a glance which of their towers they have paid to
		# improve, and a row of small bright squares is legible at sixteen
		# pixels in a way that a recoloured sprite is not.
		for pip in maxi(int(on.get("level", 1)) - 1, 0):
			var mark := ColorRect.new()
			mark.color = Color(1.0, 0.86, 0.42, 0.95)
			mark.position = Vector2(cell) * float(GameData.TILE_SIZE) 				+ Vector2(2.0 + pip * 4.0, 1.0)
			mark.size = Vector2(3.0, 3.0)
			_occupants.add_child(mark)
			_sprites.append(mark)


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
		var shadow := Sprite2D.new()
		shadow.name = "Shadow"
		shadow.texture = load(PlayerView.SHADOW)
		shadow.position.y = -1.0
		shadow.modulate.a = PlayerView.SHADOW_ALPHA
		shadow.show_behind_parent = true
		sprite.add_child(shadow)
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
		sprite.texture = _texture_for(_pose_of(one))
		# **A hit reads at a glance.** The rules say how long something stays
		# lit; the view only turns that into white. Task 0088 adds the shake
		# and the numbers on top.
		sprite.modulate = Color(2.4, 2.2, 2.2) if int(one.get("hurt", 0)) > 0 \
			else Color(1, 1, 1)
		# **Anchored at the feet, not at a tile corner.** An enemy is no
		# longer one tile - a walker is 24x32 and the Giant 40x52 - so the
		# old "half a tile back and up" drew them with their shins in the
		# ground and their heads in the next row. Bottom-centre on the cell
		# they occupy is the same rule the player uses, and it is what makes
		# a zombie stand on the tile the rules say it is on.
		sprite.position = ArtPlacement.contact(one["pos"])
		var metadata: Dictionary = RasterArt.FRAMES.get(sprite.texture.resource_path, {})
		sprite.offset = -Vector2(metadata.get("pivot",
			Vector2i(sprite.texture.get_width() / 2, sprite.texture.get_height())))


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
	# Cell indices, so these are integers and sort as integers.
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

## The terrain atlas: a grid of tiles, generated by `tools/gen_sprites.py`
## from accepted raster tiles plus remaining `tools/sprite_maps.py` materials
## and edges. The rows are named below rather than counted,
## and `headless_check` asserts the picture is the shape this expects.
const TERRAIN_ATLAS := "res://sprites/terrain/atlas.png"

## Row 0 is `Farm.Terrain` order, because that is the order the terrain byte
## is in. A cell of that terrain reads its base tile straight off this row.
const ROW_BASE := 0
## Three frames of moving water, so a pond is not a painted pond.
const ROW_WATER := 1
## Four grasses. A farm is mostly grass, and one tile repeated is a grid the
## eye finds in about a second.
const ROW_GRASS := 2
## Sixteen composited edges: grass encroaching into whatever it meets.
const ROW_EDGE := 3
## Sixteen composited shorelines, on the water side.
const ROW_SHORE := 4
## Unused row-zero slots hold clockwise NW/NE/SE/SW caps, from raw recipes.
const CORNER_EDGE_START := 6
const CORNER_SHORE_START := 10
const CORNER_NEIGHBOURS: Array = [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1)]
const CORNER_CARDINALS: Array = [9, 3, 6, 12]

## How long one frame of the water lasts. Slow on purpose - a pond that
## shimmers is a pond that pulls the eye away from the thing being built on
## the bank. Cosmetic, so it lives here and not in `game_data`.
const WATER_FRAME_SECONDS := 0.55

## The four neighbours an edge mask is built from, in bit order: north is 1,
## east 2, south 4, west 8. **`tools/gen_sprites.py` composites its sixteen
## tiles from the same four in the same order**, and the two agreeing is what
## makes the mask a straight lookup rather than a table.
const EDGE_NEIGHBOURS: Array = [
	Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0),
]
const PROP_DIR := "res://sprites/props/"
## The enemies have their own directory, and are looked in first for anything
## `GameData.ENEMIES` knows about - a prop and a zombie could otherwise share
## a name and the prop would win by being looked up first.
const ENEMY_DIR := "res://sprites/enemies/"
## The house, the workshop, and every tower at every level. Task 0075.
const BUILDING_DIR := "res://sprites/buildings/"

## How many ticks a walk frame lasts. Cosmetic, so it is here and not in
## `game_data`: a purely visual number in the data hash would mean a
## balance-neutral tweak failed the guard.
const ENEMY_WALK_TICKS := 6
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
		source.create_tile(Vector2i(t, ROW_BASE))
	for variant in 4:
		source.create_tile(Vector2i(variant, ROW_GRASS))
	for corner in 4:
		source.create_tile(Vector2i(CORNER_EDGE_START + corner, ROW_BASE))
		source.create_tile(Vector2i(CORNER_SHORE_START + corner, ROW_BASE))
	for mask in range(1, 16):
		source.create_tile(Vector2i(mask, ROW_EDGE))
		source.create_tile(Vector2i(mask, ROW_SHORE))

	# **The water, and only its first frame is a tile.** Godot takes an
	# animation's frames from the tiles to the right of it in the atlas, and
	# those must not be tiles of their own - creating them takes the frames
	# away again and the pond stops moving with no error anywhere.
	var water := Vector2i(0, ROW_WATER)
	source.create_tile(water)
	source.set_tile_animation_frames_count(water, 3)
	for frame in 3:
		source.set_tile_animation_frame_duration(water, frame,
			WATER_FRAME_SECONDS)

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
	var id: StringName = on["id"]

	# **The house has nine tiles and no anchor.** `FARM_MAP` lays it down a
	# cell at a time, so every one of them asks for the same drawing and the
	# farm gets nine little houses. The corner of it is a fact the view can
	# work out for itself, which is cheaper than changing what a fixture is
	# in the rules and moving the determinism hash to do it.
	var at: Variant = on.get("anchor", null)
	if at == null and _fixture_corner.has(id):
		var corner: Vector2i = _fixture_corner[id]
		at = [corner.x, corner.y]
	if at == null:
		return _worn(id, on)

	var pair: Array = at
	return _worn(StringName("%s_%d_%d" % [id, cell.x - int(pair[0]),
		cell.y - int(pair[1])]), on)


## The same thing, at the level it has been paid up to and in the state it is
## in. **The level first**: a Torre III that has been chewed is still a Torre
## III, and `gen_sprites` makes a `_hurt` of every level for exactly that.
func _worn(name: StringName, on: Dictionary) -> StringName:
	var level := maxi(int(on.get("level", 1)), 1)
	var full := StringName("%s_%d" % [name, level]) if level > 1 else name
	if not _exists(full):
		full = name
	# **Firing beats damaged.** A tower that has just fired is the thing the
	# eye should be on, and a muzzle flash over a hole reads fine; a hole
	# where a flash should be reads as a tower that has stopped working.
	if _just_fired(on):
		var lit := StringName("%s_fire" % full)
		if _exists(lit):
			return lit
	if not _is_hurt(on):
		return full
	var damaged := StringName("%s_hurt" % full)
	return damaged if _exists(damaged) else full


## Whether this tower fired in the last moment.
##
## `reload` counts **down** from whatever the shot cost, so a number near the
## top is a gun that has just gone off. Read off the occupant the rules keep,
## which means the flash lands on the tick the shot did and the view is not
## guessing from a projectile it can see.
func _just_fired(on: Dictionary) -> bool:
	var left := int(on.get("reload", 0))
	if left <= 0:
		return false
	var entry: Variant = Building.entry_of(StringName(on["id"]))
	if entry == null:
		return false
	var whole := int((entry as Dictionary).get("reload_ticks", 0))
	return whole > 0 and left * 100 >= whole * FLASH_PERCENT


## Whether it has taken enough to show it. The same threshold the tint uses,
## so the art and the colour agree about when something looks battered.
func _is_hurt(on: Dictionary) -> bool:
	var entry: Variant = Building.entry_of(StringName(on["id"]))
	if entry == null:
		return false
	var full := int((entry as Dictionary).get("hp", 0))
	if full <= 0:
		return false
	return float(int(on.get("hp", full))) / float(full) < WOUNDED_AT


## Whether there is art by that name, **remembered**.
##
## `ResourceLoader.exists()` touches the filesystem. This is asked two or
## three times for every occupant on the farm, every frame, by `_worn()` - two
## hundred and fifty occupants is seven hundred and fifty file checks a frame,
## and it measured at twenty-six milliseconds of a sixteen millisecond budget
## on a busy night. The answer cannot change while the game is running, so it
## is asked once per name.
var _known: Dictionary = {}


func _exists(name: StringName) -> bool:
	if _known.has(name):
		return _known[name]
	var found := false
	for folder in [ENEMY_DIR, BUILDING_DIR, PROP_DIR]:
		if ResourceLoader.exists(str(folder) + str(name) + ".png"):
			found = true
			break
	_known[name] = found
	return found


## Where each multi-tile fixture's top-left corner is, worked out once from
## the farm itself.
var _fixture_corner: Dictionary = {}


func _find_fixture_corners() -> void:
	_fixture_corner.clear()
	if _state.is_empty():
		return
	var occupants: Dictionary = _state["occupants"]
	for idx in occupants:
		var id: StringName = (occupants[idx] as Dictionary)["id"]
		if not Farm.FIXTURES.has(id) and Building.size_of(id) == Vector2i.ONE:
			continue
		var cell := Grid.cell(int(idx))
		if not _fixture_corner.has(id):
			_fixture_corner[id] = cell
			continue
		var best: Vector2i = _fixture_corner[id]
		_fixture_corner[id] = Vector2i(mini(best.x, cell.x),
			mini(best.y, cell.y))


func _texture_for(id: StringName) -> Texture2D:
	if _textures.has(id):
		return _textures[id]

	# **Ask each directory in turn for a file with that name.**
	#
	# This used to work out which directory a name belonged to by parsing the
	# name - "the kind is the part before the first underscore" - which held
	# for `walker_walk_b` and fell over on `gun_tower_2`, where the part
	# before the first underscore is "gun". A file either exists or it does
	# not, and asking is cheaper than guessing and cannot be wrong.
	for folder in [ENEMY_DIR, BUILDING_DIR, PROP_DIR]:
		var path := str(folder) + str(id) + ".png"
		if not ResourceLoader.exists(path):
			continue
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


## Which drawing an enemy is showing.
##
## **Off the state, not off a guess.** `winding_at` is the rules' own word for
## "this one is about to hit something", and it is what the telegraph and the
## attack pose hang on. The walk alternates on the tick, so two zombies that
## arrived together do not shamble in lockstep - the id is mixed in, which
## costs nothing and is what stops a wave looking like a chorus line.
##
## There is art for a death and nothing plays it. `Combat._kill()` removes the
## entity on the tick it dies, so there is no moment to draw it in; the corpse
## it leaves is task 0077's, and `enemies/*_death.png` is waiting for it.
func _pose_of(one: Dictionary) -> StringName:
	var kind: StringName = one["kind"]
	if int(one.get("winding_at", -1)) >= 0:
		var telegraph := StringName("%s_telegraph" % kind)
		if ResourceLoader.exists(ENEMY_DIR + str(telegraph) + ".png"):
			return telegraph
		return StringName("%s_attack" % kind)
	var beat := (int(_state["tick"]) / ENEMY_WALK_TICKS
		+ int(one.get("id", 0))) % 2
	return kind if beat == 0 else StringName("%s_walk_b" % kind)


## How battered a structure looks, as a tint.
##
## White while it is whole, and by the time it is nearly gone it is dark and
## red. Below `WOUNDED_AT` only, so an untouched farm is not a farm of faintly
## grey buildings.
##
## A tint rather than a second piece of art, because there are eight
## structures and that would be eight more ASCII maps to keep in step with
## them - and because the shade is continuous, so a wall at a third reads
## differently from a wall at two thirds.
func _wear_of(on: Dictionary, id: StringName) -> Color:
	var entry: Variant = Building.entry_of(id)
	if entry == null:
		return Color.WHITE
	var full := int((entry as Dictionary).get("hp", 0))
	if full <= 0:
		return Color.WHITE
	var share := clampf(float(int(on.get("hp", full))) / float(full), 0.0, 1.0)
	if share >= WOUNDED_AT:
		return Color.WHITE
	var hurt := 1.0 - share / WOUNDED_AT     # 0 at the threshold, 1 at death
	return Color(1.0, lerpf(1.0, 0.45, hurt), lerpf(1.0, 0.38, hurt),
		1.0).darkened(hurt * 0.25)


## Below this share of its hit points a structure starts to look it.
const WOUNDED_AT := 0.75

## How much of a reload still has to be left for the muzzle to be lit. High,
## so the flash is a moment rather than a lamp: at 80 a gun on a one second
## reload is lit for about a fifth of a second after each shot.
const FLASH_PERCENT := 80


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
