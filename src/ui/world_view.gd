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

## **A cap, so nothing can shake the screen to pieces.** Six pixels is a
## fortieth of a 270-pixel screen: enough to feel, small enough that the farm
## never stops being readable. A mortar landing on eight zombies asks for far
## more than this and gets six.
const SHAKE_CAP := 6.0

## How fast a shake dies away, as a fraction of itself a second.
const SHAKE_DECAY := 9.0
## Follow continuous coordinates on both axes. Picking uses the same transform.
const CAMERA_RESPONSE := 10.0

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
## Existing production jobs drive a bounded cached-sprite update. This never
## allocates occupant nodes or adds a timer to simulation state.
var _stations: Array[Sprite2D] = []
## The defences under a tarp (task 0223), and the stage they were last
## dressed for.
var _tarped: Array[Sprite2D] = []
var _tarp_stage := -1
## The decoys' sprites by cell index, made again with the rest (task 0224),
## and what each was last seen at: its hit points, and how long since a bite.
var _decoys: Dictionary = {}
var _decoy_hits: Dictionary = {}
## **Whether the day's tarps are drawn** (task 0223): yes in the game. The
## tower showcase turns them off, to look at the towers by daylight.
var tarps := true
const AMBIENT_MOTION := preload("res://src/ui/ambient_motion.gdshader")
## **A wraith's fade** (task 0252): the shader that turns its presence into a
## shade - one material for every wraith on the farm.
const WRAITH_FADE := preload("res://src/ui/wraith_fade.gdshader")
var _ambient_materials: Array[ShaderMaterial] = []
## **The season on screen** (task 0159): the remap the ground and the trees
## wear, the roofs' snow and the caps'. Its own node; see `SeasonView`.
var _season: SeasonView = SeasonView.new()
## How many times the terrain's cells have been laid - which a season must
## never add to - and the atlas they are drawn from now.
var _terrain_draws := 0
var _ground_file := ""
var _ambient_time := 0.0
var ambient_running := true
var _station_due := 0.0

## A frame around the cell the player would act on, drawn over the terrain and
## under everything standing on it. Task 0023 reuses it for the build ghost.
var _highlight: Node2D
var _highlight_cell := Vector2i(-1, -1)
var _highlight_cells: Array = []
## **The route a wall would leave** (task 0157), on the night cues' layer: out
## of the night's tint, and over the trees and the roofs a route from the
## north runs under.
var _route_dots: Node2D

## The field: turned earth and whatever is growing in it. Flat on the ground
## rather than standing on it, because a crop is not something you walk around
## - and at night it is ground to defend, not furniture.
var _plots: Node2D
var _plot_sprites: Array[Node] = []
var _plots_signature := 0
## The lawn cells the hoe had turned when the edges were last laid, by cell
## index: a bed's grass edge stops at a turned lawn (`_relay_edges_for_turned`).
var _turned_seen: Dictionary = {}

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
## The bees on the stung, out of the night's ramp (task 0226), and their pool.
var _swarms: Node2D
var _swarm_sprites: Array[Sprite2D] = []
## The zaps where a stun lands, out of the ramp too (task 0230): the ones
## playing, `{"sprite", "age"}` oldest first, and each enemy's stun last
## frame, by id - a longer one this frame is a fresh shock.
var _zaps: Node2D
var _zap_cues: Array = []
var _stunned: Dictionary = {}
## The powers' marks, out of the ramp as well (task 0233): the bell's rings
## and a mended structure's square (`_draw_powers`).
var _marks: Node2D
var _actor_sprites: Array[Node] = []
var _shots: Node2D
## Only presentation remembers launch points and the level of destroyed towers.
## Both caches are bounded by current projectiles / standing or rubble cells.
var _shot_before: Dictionary = {}
var _shot_origins: Dictionary = {}
var _observing_tick := false
var _enemy_motion := EnemyMotion.new()
var _enemy_warning: Node2D
var _enemy_deaths := EnemyDeaths.new()
var _death_sprites: Array[Sprite2D] = []
## Dawn: the survivors of a lost night walking off, after the rules removed them.
var _enemy_retreats := EnemyRetreats.new()
var _retreat_sprites: Array[Sprite2D] = []
var _tower_history: Dictionary = {}
var _tower_version := -1
var _wrecks: Node2D
var _wreck_sprites: Dictionary = {}
var _wreck_signature := -1
## A mine has no surviving core entity after detonation. Observe only actual
## consumption, excluding sales/destruction, and keep its short cue in the view.
const MINE_TRIGGER_SECONDS := 0.16
const MINE_SPENT_SECONDS := 0.24
const MINE_CUE_CAP := 6
var _ground_traps: Node2D
var _mine_before: Dictionary = {}
var _mine_sprung_before := 0
var _mine_selling := -1
var _mine_cues: Dictionary = {}
## The pumpkins in the air last frame (task 0227), by shot id: the cell each
## was thrown at, for its splat once it is gone; and the splats bursting now,
## `{"sprite", "age"}`, oldest first.
var _pumpkins: Dictionary = {}
var _splats: Array = []
## The spitters' globs in the air last frame (task 0247), by who spat and
## when: the cell each was aimed at, for its splat once it has landed.
var _globs: Dictionary = {}
## Where they are drawn (task 0247): the night cues' layer, out of the
## night's tint, as the bees and the zaps are.
var _spit: Node2D
## Which way each untracked enemy last moved (task 0247's spitter), by id:
## `[x, faces_right]`. Pictures only; the rules have no facing.
var _heading: Dictionary = {}
## How much of each wraith shows, by id, eased towards its light's (task
## 0252), and the one material their fade shares.
var _presence: Dictionary = {}
var _wraith_fade: ShaderMaterial
var _mine_tick_before := -1
var _mine_losses_before: Dictionary = {}
var _mine_grid_version := -1
var _mine_cells: Array = []

## The light. One node, two colours, and whatever is between them right now.
var _light: CanvasModulate
var _lit_for := -1                  # the phase the fade is heading towards
var _fade := 1.0                    # 0 at the start of a change, 1 when done
var _fade_from := Color.WHITE       # where the fade started
var _fade_ramp: Dictionary = {}
var _worn_ramp: Dictionary = {}
var _fade_nightness := 0.0
## The rest of the ramp. A sibling layer, so it can sit over the whole world
## and under the whole HUD; null when the view is opened on its own.
var _relight: Relight

## The Zzz over the sleeping house (task 0129), and how far it drifts up
## through one loop of its frames, in world pixels.
const ZZZ_RISE := 6.0
const ZZZ_ON_ROOF := 14.0
var _zzz: Sprite2D
var _zzz_time := 0.0
var _zzz_textures: Dictionary = {}

## The guardian's cursor and the porch guardian (task 0131).
var _cursor: GuardianCursor
var _guardian: GuardianView
## The barnyard: animals at home, the dog, dig spots (task 0185).
var _animal_view: AnimalView
## What the night left lying about (task 0221).
var _loot_view: LootView
var _peddler_view: PeddlerView
var _house_mark: Node2D
var _house_mark_for := ""
## The cells with a defence on them last time the occupants changed, so a new
## one can be spotted (task 0133) - empty until the first look at a state.
var _defences_seen: Dictionary = {}
var _defences_known := false


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
	# **The season on the ground** (task 0159): one material on the terrain,
	# its edges and its corners, switched by a uniform.
	add_child(_season)
	_terrain.material = _season.ground
	_edges.material = _season.ground
	for layer in _corners:
		layer.material = _season.ground
	_ground_file = TERRAIN_ATLAS

	# Camera limits are the farm's edges, so panning can never show a gap or a
	# repeated column - the engine does the clamping and no arithmetic here can
	# get it wrong.
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = WORLD_SIZE.x
	_camera.limit_bottom = WORLD_SIZE.y
	_camera.position_smoothing_enabled = false # Smoothed once in follow_player.
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

	_enemy_warning = Node2D.new()
	_enemy_warning.name = "EnemyWarning"
	_enemy_warning.z_index = 7
	_enemy_warning.draw.connect(_draw_enemy_warning)
	add_child(_enemy_warning)

	_shots = Node2D.new()
	_shots.name = "Shots"
	_shots.z_index = 8              # over everything on the ground
	_shots.draw.connect(_draw_shots)
	add_child(_shots)

	# **Out of the night's tint**, the way the particles' warm effects are:
	# its own layer following the camera, so world pixels still place them -
	# the Zzz stays the lightest thing over the dark house and the cursor
	# reads over dark ground. Created here, before `HouseView`, so the bed
	# beat's room still covers them.
	var cue_layer := CanvasLayer.new()
	cue_layer.name = "NightCues"
	cue_layer.layer = 2
	cue_layer.follow_viewport_enabled = true
	add_child(cue_layer)
	# The route preview first, so the Zzz and the cursor sit over it.
	_route_dots = Node2D.new()
	_route_dots.name = "RoutePreview"
	_route_dots.draw.connect(_draw_route)
	cue_layer.add_child(_route_dots)
	# **The powers' marks** (task 0233) over it: cues, which the night must
	# not grey out, and the bell's sound goes over the roofs.
	_marks = Node2D.new()
	_marks.name = "PowerMarks"
	_marks.draw.connect(_draw_powers)
	cue_layer.add_child(_marks)
	# **The bees on the stung** (task 0226), over the route and under the
	# Zzz and the cursor (`_place_swarms`).
	_swarms = Node2D.new()
	_swarms.name = "Swarms"
	cue_layer.add_child(_swarms)
	# **The zaps where a stun lands** (task 0230), beside them.
	_zaps = Node2D.new()
	_zaps.name = "Zaps"
	cue_layer.add_child(_zaps)
	# **A spitter's globs and their splats** (task 0247), beside them: the
	# night greyed a green glob to a pebble, and the spit has to be seen
	# crossing the dark.
	_spit = Node2D.new()
	_spit.name = "Spit"
	_spit.draw.connect(_draw_spit)
	cue_layer.add_child(_spit)
	_zzz = Sprite2D.new()
	_zzz.name = "Zzz"
	_zzz.centered = false
	_zzz.region_enabled = true
	_zzz.visible = false
	cue_layer.add_child(_zzz)
	_cursor = GuardianCursor.new()
	_cursor.name = "GuardianCursor"
	_cursor.setup(self)
	cue_layer.add_child(_cursor)

	# The porch guardian stands in the world, lit by the ramp like the house
	# it guards; only its eyes glow (`lighting.gd`).
	_guardian = GuardianView.new()
	_guardian.name = "Guardian"
	_occupants.add_child(_guardian)

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
	move_child(_highlight, _plots.get_index() + 1) # above soil/crops, below occupants
	_wrecks = Node2D.new()
	_wrecks.name = "TowerWrecks"
	add_child(_wrecks)
	move_child(_wrecks, _occupants.get_index())
	_ground_traps = Node2D.new()
	_ground_traps.name = "GroundTraps"
	add_child(_ground_traps)
	move_child(_ground_traps, _occupants.get_index())
	# **The barnyard** (task 0185): the animals at home wandering by their
	# coop or barn, the dog, and the pigs' dig spots - view only, never the
	# state's.
	_animal_view = AnimalView.new()
	_animal_view.name = "AnimalView"
	add_child(_animal_view)
	_animal_view.setup(_occupants, _ground_traps)
	# **What the night left lying about** (task 0221): the bone piles and
	# the moon stones on the ground, under the boots and beside the dig
	# spots - view only.
	_loot_view = LootView.new()
	_loot_view.name = "LootView"
	add_child(_loot_view)
	move_child(_loot_view, _ground_traps.get_index())
	# **The peddler** (task 0190): at the stall in its hours, and the stall
	# shut outside them - view only.
	_peddler_view = PeddlerView.new()
	_peddler_view.name = "PeddlerView"
	add_child(_peddler_view)
	_peddler_view.setup(_occupants)
	# **The house's tier, marked** (task 0191): a plaque over the door, sorted
	# with the house it hangs on.
	_house_mark = Node2D.new()
	_house_mark.name = "HouseMark"
	_house_mark.draw.connect(_draw_house_mark)
	_occupants.add_child(_house_mark)


## Where the plaque goes and whether it changed: the house's bottom middle,
## for the sort, and its tier.
func _place_house_mark() -> void:
	if _house_mark == null or _state.is_empty():
		return
	var bounds := Farm.house_bounds(_state)
	var tile := float(GameData.TILE_SIZE)
	var at := Vector2((float(bounds.position.x) + float(bounds.size.x) * 0.5) * tile,
		float(bounds.position.y + bounds.size.y) * tile)
	var signature := "%s/%d" % [str(at), House.tier(_state)]
	if signature == _house_mark_for:
		return
	_house_mark_for = signature
	# **A pixel below the house's own sort line**, which is this same
	# bottom middle: on a tie the house, built after the plaque, drew over it.
	_house_mark.position = at + Vector2(0.0, 1.0)
	_house_mark.queue_redraw()


## **Tiers II and III through 0120's road** (task 0191): today's house with a
## plaque over its door - two gold studs, or three - until A035's drawings of
## the sturdier houses land in 0217. Nothing for tier I, or once the tier's
## own drawing is in.
func _draw_house_mark() -> void:
	var tier := House.tier(_state) if not _state.is_empty() else 1
	if tier < 2 or PlaceholderArt.art(StringName("house_%d" % tier)).is_empty():
		return
	var width := float(tier) * 4.0 + 2.0
	var at := Vector2(-width * 0.5, -HOUSE_MARK_ABOVE - 1.0)
	_house_mark.draw_rect(Rect2(at - Vector2(1, 1), Vector2(width + 2.0, 7.0)), PaletteData.COLOURS.get(&"ink", Color.BLACK))
	_house_mark.draw_rect(Rect2(at, Vector2(width, 5.0)), PaletteData.COLOURS.get(&"wood_dark", Color(0.42, 0.29, 0.17)))
	for i in tier:
		_house_mark.draw_rect(Rect2(at + Vector2(2.0 + float(i) * 4.0, 1.0), Vector2(2.0, 3.0)),
			PaletteData.COLOURS.get(&"gold", Color(0.77, 0.59, 0.27)))


## How far above the house's ground line the plaque's top is: on the beam
## over the door, whose top is about 34 above it.
const HOUSE_MARK_ABOVE := 41.0


## The peddler's drawing (task 0190), for the checks and the pictures.
func peddler_view() -> PeddlerView:
	return _peddler_view


## Point the view at a game. Called by whatever screen owns the simulation.
func show_state(state: Dictionary) -> void:
	if not is_same(_state, state):
		_enemy_motion.clear()
		_enemy_deaths.clear()
		_refresh_deaths(0.0)
		_enemy_retreats.clear()
		_refresh_retreats(0.0)
		_shot_before.clear()
		_shot_origins.clear()
		_observing_tick = false
		_tower_history.clear()
		_tower_version = -1
		_wreck_signature = -1
		_mine_before.clear()
		_mine_losses_before.clear()
		_mine_grid_version = -1
		_mine_cells.clear()
		_clear_mine_cues()
	if not is_same(_state, state):
		_defences_known = false
	_state = state
	if _guardian != null:
		_guardian.show_state(state)
	if _animal_view != null:
		_animal_view.show_state(state)
	if _loot_view != null:
		_loot_view.show_state(state)
	if _peddler_view != null:
		_peddler_view.show_state(state)
	_remember_towers(state)
	_dirty = true
	if _season != null:
		_season.show_state(state)
		_apply_ground_art()
	_draw_terrain()
	_refresh()
	_refresh_plots()
	_refresh_wrecks()
	_process_mine_cues(0.0)


## Redraw the occupants next frame. Called by anything that knows it changed
## the farm; the signature check below catches the rest.
func mark_dirty() -> void:
	_dirty = true


func _process(delta: float) -> void:
	if _state.is_empty():
		return
	_shake_camera(delta)
	_light_for_phase(delta)
	# **The season moves at the wake-up** (task 0159), every material in the
	# same frame; the occupants and the plots are redrawn for their seasonal
	# frames and caps, the terrain's cells never.
	if _season != null and _season.update():
		_apply_ground_art()
		_dirty = true
		_plots_signature = -1
	# **Not rebuilt every frame.** Godot's Dictionary hash is cheap and exact
	# enough to notice a placement or a removal; the determinism hash is a
	# different thing for a different job and is not used here.
	# House HP lives outside the occupants table; crossing the existing wear
	# threshold must refresh its drawing even when all nine cells are unchanged.
	# So does its tier (task 0191), which picks the drawing.
	var signature: int = [(_state["occupants"] as Dictionary).hash(), _house_hurt(), House.tier(_state)].hash()
	if signature != _last_signature:
		_last_signature = signature
		_dirty = true
		_watch_defences()
	if _dirty:
		_dirty = false
		_refresh()

	var plots: int = (_state["plots"] as Dictionary).hash()
	if plots != _plots_signature:
		_plots_signature = plots
		_refresh_plots()

	_refresh_actors(delta)
	_refresh_ambient(delta)
	_refresh_zzz(delta)
	_refresh_deaths(delta)
	_refresh_retreats(delta)
	_enemy_warning.queue_redraw()
	_refresh_stations(delta)
	_sway_decoys(delta)
	_dress_tarps()
	_place_house_mark()
	_remember_towers(_state)
	_refresh_wrecks()
	_process_mine_cues(delta)
	_refresh_splats(delta)
	_refresh_zaps(delta)
	_redraw_marks()
	if _shots != null:
		# Skipping a night does not emit per-tick observer signals.
		var alive: Dictionary = {}
		for shot in (_state["projectiles"] as Array):
			alive[int(shot["id"])] = true
		for id in _shot_origins.keys():
			if not alive.has(id):
				_shot_origins.erase(id)
		_shots.queue_redraw()
	if _spit != null and _actors != null:
		_spit.transform = _actors.get_global_transform()
		_spit.queue_redraw()


# -------------------------------------------------------------------- light

## Move the light towards whatever the phase asks for.
##
## PREPARATION counts as night: the sun is down and the first zombie is on its
## way, and a build step lit like an afternoon would be lying about what is
## about to happen.
func _light_for_phase(delta: float) -> void:
	var phase := int(_state["phase"])
	var wants_day := phase == Phases.DAY
	var target: Color = _daylight_now() if wants_day \
		else _night_ramp()["tint"]

	if phase != _lit_for:
		_fade_nightness = visual_nightness()
		# Only a change between the two realities is worth a fade; DAY to DAY
		# after a result screen is not a transition, it is the same light.
		var was_day := _lit_for == Phases.DAY or _lit_for == -1
		_fade = 1.0 if was_day == wants_day else 0.0
		_fade_from = _light.color
		_fade_ramp = _worn_ramp.duplicate() if not _worn_ramp.is_empty() else _ramp_of(_fade_from)
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
	_wear(_blend(_fade_ramp, _ramp_now(), _fade))


## The colour of the daylight right now, read off the clock: cool at dawn
## (06:00), plain at noon, warm at dusk (18:00), and deepening after it until
## the day ends at 02:00.
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
	var leg := _light_leg()
	var ends := [PaletteData.DAWN_TINT, PaletteData.DAY_TINT,
		PaletteData.DUSK_TINT, _night_ramp()["tint"]]
	return (ends[int(leg[0])] as Color).lerp(ends[int(leg[0]) + 1], float(leg[1]))


## Noon on the clock: the middle of the light's first two legs.
const NOON_MINUTE := 12 * 60

## How far towards the night the evening has gone by the end of the day. The
## light keeps deepening after dusk instead of stopping at it, but not all the
## way: the night proper is still a change the player sees happen.
const EVENING_DEPTH := 0.5


## Where the light is on its way through the day, **read off the hour**
## (task 0126): `[leg, weight]`, leg 0 dawn to noon (06:00-12:00), leg 1 noon
## to dusk (12:00-18:00), leg 2 dusk deepening towards the night until the day
## ends at 02:00, at most `EVENING_DEPTH` of the way.
func _light_leg() -> Array:
	var minute := float(Phases.clock_minute(_state))
	var start := float(GameData.DAY_START_MINUTE)
	var dusk := float(GameData.DUSK_MINUTE)
	var end := float(GameData.DAY_END_MINUTE)
	var noon := clampf(float(NOON_MINUTE), start + 1.0, dusk - 1.0)
	if minute <= noon:
		return [0, clampf((minute - start) / (noon - start), 0.0, 1.0)]
	if minute <= dusk:
		return [1, clampf((minute - noon) / (dusk - noon), 0.0, 1.0)]
	return [2, clampf((minute - dusk) / maxf(end - dusk, 1.0), 0.0, 1.0)
		* EVENING_DEPTH]


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
	var leg := _light_leg()
	var ends := [_dawn_ramp(), _day_ramp(), _dusk_ramp(), _night_ramp()]
	return _blend(ends[int(leg[0])], ends[int(leg[0]) + 1], float(leg[1]))


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


## The night's ramp - **a Full Moon's when tonight is one** (task 0152):
## brighter, and still night. The evening deepens towards it too, so a Full
## Moon's dusk already looks like one.
func _night_ramp() -> Dictionary:
	if _tonight_is_full_moon():
		return {"tint": PaletteData.FULL_MOON_TINT, "lift": PaletteData.FULL_MOON_LIFT,
			"saturation": PaletteData.FULL_MOON_SATURATION,
			"warm_keep": PaletteData.FULL_MOON_WARM_KEEP,
			"warm_edge": PaletteData.FULL_MOON_WARM_EDGE}
	return {"tint": PaletteData.NIGHT_TINT, "lift": PaletteData.NIGHT_LIFT,
		"saturation": PaletteData.NIGHT_SATURATION,
		"warm_keep": PaletteData.NIGHT_WARM_KEEP,
		"warm_edge": PaletteData.NIGHT_WARM_EDGE}


## Whether the night this farm is in, or heading for, is a Full Moon: the
## night being fought once it has begun, today's date before.
func _tonight_is_full_moon() -> bool:
	if _state.is_empty():
		return false
	var phase := int(_state.get("phase", Phases.DAY))
	var night := int(_state["night"]) if phase == Phases.NIGHT or phase == Phases.RESULT \
		else Phases.night_ahead(_state)
	return Calendar.is_full_moon(night)


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
	_worn_ramp = ramp.duplicate()
	if _relight == null:
		return
	_relight.apply(_light.color, ramp["lift"], ramp["saturation"],
		ramp["warm_keep"], ramp["warm_edge"])


## The ramp the light is heading for, for `input_check` to read back.
func ramp_target() -> Dictionary:
	return _ramp_now()


## **Where the tarps are now** (task 0223), off the light's own change.
func tarp_stage() -> int:
	return Transition.tarp_stage(going_dark(), is_transitioning(),
		transition_progress(), _transition_seconds)


## A tarp on a defence (task 0223): a child at the same ground pivot, so it
## sorts with the defence it covers; what the defence draws is hidden while
## the cover is on, and the unveil frames are drawn over it. A hurt one's
## cover is torn, so the morning never hides the night's damage - and a
## defence that came down is rubble, swept at dawn, with nothing to cover.
func _tarp(sprite: Sprite2D, footprint: StringName, hurt: bool) -> void:
	var cover := Sprite2D.new()
	cover.name = "Tarp"
	cover.centered = false
	cover.offset = -Vector2(TarpArt.pivot(footprint))
	cover.set_meta("tarp", footprint)
	cover.set_meta("hurt", hurt)
	sprite.add_child(cover)
	_tarped.append(sprite)
	_dress_tarp(sprite, tarp_stage())


## Every tarp to the stage the change is at, when it moves.
func _dress_tarps() -> void:
	var stage := tarp_stage()
	if stage == _tarp_stage:
		return
	_tarp_stage = stage
	for sprite in _tarped:
		if is_instance_valid(sprite):
			_dress_tarp(sprite, stage)


func _dress_tarp(sprite: Sprite2D, stage: int) -> void:
	var cover := sprite.get_node_or_null(^"Tarp") as Sprite2D
	if cover == null:
		return
	sprite.self_modulate.a = 0.0 if stage == TarpArt.COVERED else 1.0
	cover.texture = TarpArt.texture(StringName(cover.get_meta("tarp")), stage,
		bool(cover.get_meta("hurt")))
	cover.visible = cover.texture != null


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


## Actor fading follows the same displayed light, even after a reversal.
func visual_nightness() -> float:
	var target := 0.0 if _lit_for in [-1, Phases.DAY] else 1.0
	return lerpf(_fade_nightness, target, transition_progress())


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
		return _night_ramp()["tint"]
	# **The day's light, at the hour it is.** This returned the noon
	# constant, which was right until task 0039 gave the sun somewhere to
	# travel - after which it was a function that reported where the light
	# used to go rather than where it is going, which is the one thing a
	# test is meant to be able to ask.
	return _daylight_now()


# ------------------------------------------------------------------- camera

## Frame the cell the player would act on, or nothing when there is nothing to
## act on. Called each frame; redraws when its cell or eligible area changes.
func highlight(cell: Vector2i) -> void:
	var cells: Array = [cell] if Grid.in_bounds(cell) else []
	if not _state.is_empty():
		var verb := Interact.verb_at(_state, cell)
		if verb in [&"water", &"till"]:
			cells = Farming.action_cells(_state, cell, verb)
	if cell == _highlight_cell and cells == _highlight_cells:
		return
	_highlight_cell = cell
	_highlight_cells = cells
	if _highlight != null:
		_highlight.queue_redraw()


## What the next stroke will actually affect, without exposing the view's cache.
func highlighted_cells() -> Array:
	return _highlight_cells.duplicate()


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
	if _route_dots != null:
		_route_dots.queue_redraw()


func clear_route() -> void:
	show_route([])


func previewed_route() -> Array:
	return _preview


func show_ghost(cell: Vector2i, id: StringName, ok: bool) -> void:
	if _ghost == null:
		return
	var size := float(GameData.TILE_SIZE)
	_ghost.texture = _texture_for(_barrier_name({"id": id}, cell) if connected_barrier(id) else id)
	ArtPlacement.place(_ghost, cell, Building.size_of(id))
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
	return Building.size_of(_ghost_id)


func hide_ghost() -> void:
	if _ghost == null or not _ghost.visible:
		return
	_ghost.visible = false
	_ghost_cell = Vector2i(-1, -1)
	if _highlight != null:
		_highlight.queue_redraw()


func _draw_enemy_warning() -> void:
	if _state.is_empty():
		return
	var size := float(GameData.TILE_SIZE)
	# **What the Giant is about to hit.** A ring closing on the cell it has
	# picked, so the second the telegraph buys is a second the player can see
	# and spend. Drawn from the rules' own wind-up, so it cannot promise a
	# blow that is not coming.
	for id in Entities.ids(_state):
		var aimed := Enemies.winding_at(_state, id)
		if aimed.x < 0:
			continue
		# **A freeze's reach** (task 0255): the square of ground the Winter
		# Lord's cast will freeze every tower on, from the rules' own cells,
		# laid on the ground in ice and edged, pulsing while it casts.
		var aura := Enemies.aura_cells(_state, int(id))
		if not aura.is_empty():
			var pulse := fmod(float(Time.get_ticks_msec()) / 400.0, 1.0)
			var reach := Rect2(Vector2(aura[0] as Vector2i) * size, Vector2(size, size))
			for cell in aura:
				reach = reach.merge(Rect2(Vector2(cell as Vector2i) * size, Vector2(size, size)))
			_enemy_warning.draw_rect(reach, Color(AURA_GROUND, AURA_GROUND.a * (0.7 + 0.3 * pulse)))
			_enemy_warning.draw_rect(reach.grow(-1.0), AURA_EDGE, false, 2.0)
			continue
		# **A cast's cells** (task 0254): a ring closing on every cell the
		# flock will rise on, from the rules' own list - where the crows will
		# be, the moment the cast ends.
		var flock := Enemies.flock_cells(_state, int(id))
		if not flock.is_empty():
			var beat := fmod(float(Time.get_ticks_msec()) / 400.0, 1.0)
			for cell in flock:
				_enemy_warning.draw_arc((Vector2(cell as Vector2i) + Vector2(0.5, 0.5)) * size,
					size * (0.6 - 0.25 * beat), 0.0, TAU, 16, Color(1.0, 0.45, 0.30, 0.9), 2.0, true)
			continue
		# The same observed wind-up drives both body and ring. A post-hit
		# cooldown or stale target while walking must not promise another slam.
		if not EnemyMotion.is_windup(_pose_of(Entities.get_one(_state, int(id)))):
			continue
		var swing := fmod(float(Time.get_ticks_msec()) / 400.0, 1.0)
		# **A charge's line** (task 0253): a strip on every cell it will
		# enter, pulsing, from the rules' own line - where it ends is where
		# something will hold, or the house.
		var line := Enemies.charge_line(_state, int(id))
		if not line.is_empty():
			var strip := Rect2(Vector2(line[0] as Vector2i) * size, Vector2(size, size))
			for cell in line:
				var box := Rect2(Vector2(cell as Vector2i) * size, Vector2(size, size))
				strip = strip.merge(box)
				_enemy_warning.draw_rect(box.grow(-1.0), Color(CHARGE_STRIP, CHARGE_STRIP.a * (0.7 + 0.3 * swing)))
			# Edged in the ring's red: under the night's ramp a fill alone was
			# a pink smudge over the walls (the first take).
			_enemy_warning.draw_rect(strip.grow(-1.0), Color(1.0, 0.45, 0.30, 0.9), false, 2.0)
			continue
		var middle := (Vector2(aimed) + Vector2(0.5, 0.5)) * size
		_enemy_warning.draw_arc(middle, size * (1.4 - 0.6 * swing), 0.0, TAU, 24,
			Color(1.0, 0.45, 0.30, 0.9), 2.0, true)



## **The route a wall would leave**, dotted so it reads as a prediction
## rather than as something on the farm.
func _draw_route() -> void:
	if _preview.is_empty():
		return
	var size := float(GameData.TILE_SIZE)
	# **The ground the garlic holds** (task 0228), faint under the dots while
	# a preview is up: the route is drawn bending round something, and this is
	# the something. Read off the rules' own area, never worked out here.
	if not _state.is_empty():
		var area: PackedByteArray = _state.get("repel", PackedByteArray())
		if area.size() == Grid.CELLS:
			for idx in Grid.CELLS:
				if int(area[idx]) > 0:
					_route_dots.draw_rect(Rect2(Vector2(Grid.cell(idx)) * size,
						Vector2(size, size)), GARLIC_GROUND)
	var step := 0
	for found in _preview:
		step += 1
		if step % 2 == 0:
			continue
		var cell: Vector2i = found
		_route_dots.draw_rect(Rect2(Vector2(cell) * size
			+ Vector2(size, size) * 0.4, Vector2(size, size) * 0.2),
			Color(1.0, 0.85, 0.45, 0.75))


func _draw_highlight() -> void:
	if _state.is_empty():
		return
	var size := float(GameData.TILE_SIZE)

	# **The flare.** An expanding ring at the player's feet, fading as it goes,
	# so the one button reads as something that happened *there* rather than a
	# number changing in a corner.
	#
	# Drawn entirely from what the rules already recorded - where it went off
	# and how many ticks are left - so there is nothing for the view to
	# remember and nothing here that could disagree with the damage.
	var burst := Ability.aimed_at(_state, Ability.FLARE)
	if not burst.is_empty():
		var full := maxf(float(GameData.ABILITY["flare_ticks"]), 1.0)
		var left := float(Ability.showing(_state, Ability.FLARE))
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

	# A frame rather than a fill: the player needs to see what is on the tile
	# as well as that it is selected.
	for at in _highlight_cells:
		var rect := Rect2(Vector2(at) * size, Vector2(size, size))
		_highlight.draw_rect(rect, Color(1.0, 0.98, 0.85, 0.85), false, 1.0)
		_highlight.draw_rect(rect.grow(-1.0), Color(0.0, 0.0, 0.0, 0.25), false, 1.0)


## **The powers' marks fade by the tick** (task 0233), and the layer they
## are drawn on otherwise waits for the cursor to move: drawn again every
## frame one shows - the flare's ring too, which until then stood still under
## a still pointer - and once after, to clear the last.
func _redraw_marks() -> void:
	var marked := false
	for id in Ability.ORDER:
		marked = marked or Ability.showing(_state, id) > 0
	if marked or _marked:
		if _highlight != null:
			_highlight.queue_redraw()
		if _marks != null:
			_marks.queue_redraw()
	_marked = marked


## Whether a power's mark showed last frame (`_redraw_marks`).
var _marked := false


## **The other powers' marks** (task 0233), drawn from what the rules
## recorded, as the flare's ring is, on the night cues' layer: the bell's
## brass rings going out from the house over the farm while it sounds, each
## fading as it goes, and a mended structure's warm square closing in on it.
func _draw_powers() -> void:
	if _state.is_empty():
		return
	var size := float(GameData.TILE_SIZE)
	var bell := float(Ability.showing(_state, Ability.FARM_BELL))
	if not Ability.aimed_at(_state, Ability.FARM_BELL).is_empty():
		var full := maxf(float(int((GameData.POWERS[Ability.FARM_BELL] as Dictionary)["show_ticks"])), 1.0)
		var grown := 1.0 - bell / full
		var house := (Vector2(Farm.house_centre(_state)) + Vector2(0.5, 0.5)) * size
		for ring in BELL_RINGS:
			var out := fmod(grown + float(ring) / float(BELL_RINGS), 1.0)
			_marks.draw_arc(house, BELL_REACH * size * out, 0.0, TAU, 64,
				Color(PaletteData.COLOURS[&"gold_light"], 0.8 * (1.0 - out) * minf(bell / full * 2.0, 1.0)),
				2.0, true)
	var mended := Ability.aimed_at(_state, Ability.EMERGENCY_REPAIR)
	if not mended.is_empty():
		var left := float(Ability.showing(_state, Ability.EMERGENCY_REPAIR))
		var full := maxf(float(int((GameData.POWERS[Ability.EMERGENCY_REPAIR] as Dictionary)["show_ticks"])), 1.0)
		var anchor := Vector2i(int(mended[0]), int(mended[1]))
		var box := Rect2(Vector2(anchor) * size, Vector2(Building.bounds_at(_state, anchor).size) * size)
		var closing := box.grow(size * 0.75 * left / full)
		_marks.draw_rect(closing, Color(PaletteData.COLOURS[&"grass_light"], 0.9 * left / full), false, 2.0)
		_marks.draw_rect(box, Color(PaletteData.COLOURS[&"flame_hot"], 0.25 * left / full), true)


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
	_camera.position = _camera_bounds((Vector2(cell) + Vector2.ONE * 0.5) * GameData.TILE_SIZE)
	_camera.force_update_scroll()


## Follow subtile motion rather than jumping a whole tile at cell boundaries.
##
## **No zoom.** Like Stardew Valley, the scale is fixed: a 16px tile is 64
## screen pixels at 1920x1080, so the farmer is always two tiles tall.
func follow_player(subtile: Vector2i, delta: float) -> void:
	var weight := 1.0 - exp(-CAMERA_RESPONSE * maxf(delta, 0.0))
	var target := Vector2(subtile) * (float(GameData.TILE_SIZE) / Player.SUBTILE)
	_camera.position = _camera_bounds(_camera.position.lerp(_camera_bounds(target), weight))
	_camera.force_update_scroll()


## **The night camera** (task 0130): moved by the player rather than by the
## farmer. `direction` is up to 1 a side, and a diagonal is no faster than a
## straight line. `seconds` is real time, so 2x and 4x do not speed it up.
## Clamped like every other camera move, with no zoom.
func pan_camera(direction: Vector2, seconds: float) -> void:
	if direction == Vector2.ZERO:
		return
	_camera.position = _camera_bounds(_camera.position
		+ direction.limit_length(1.0) * GameData.CAMERA_PAN_SPEED * maxf(seconds, 0.0))
	_camera.force_update_scroll()


## Where the camera is looking, in world pixels - for the tests and the shots.
func camera_centre() -> Vector2:
	return _camera.position


## Move the camera just enough that `point` is at least `margin` world pixels
## inside the view - how the camera follows a pad-stepped cursor (task 0131).
func keep_in_view(point: Vector2, margin: float) -> void:
	var half := get_viewport_rect().size * 0.5 - Vector2.ONE * margin
	var centre := _camera.position
	var wanted := Vector2(clampf(centre.x, point.x - half.x, point.x + half.x),
		clampf(centre.y, point.y - half.y, point.y + half.y))
	if wanted != centre:
		_camera.position = _camera_bounds(wanted)
		_camera.force_update_scroll()


## The guardian's cursor (task 0131).
func cursor() -> GuardianCursor:
	return _cursor


## The porch guardian (task 0131).
func guardian() -> GuardianView:
	return _guardian


## Put the camera's centre on a world point, clamped - the shots' hook.
func look_at_point(point: Vector2) -> void:
	_camera.position = _camera_bounds(point)
	_camera.force_update_scroll()


func _camera_bounds(point: Vector2) -> Vector2:
	var half := get_viewport_rect().size * 0.5
	var world := Vector2(WORLD_SIZE)
	return Vector2(world.x * 0.5 if half.x * 2.0 >= world.x else clampf(point.x, half.x, world.x - half.x),
		world.y * 0.5 if half.y * 2.0 >= world.y else clampf(point.y, half.y, world.y - half.y))


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
	_terrain_draws += 1
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
	var turned := _turned_grass()
	_turned_seen = turned
	for idx in Grid.CELLS:
		var cell := Grid.cell(idx)
		var at := _edge_tile(bytes, cell, int(bytes[idx]), turned)
		if at.x >= 0:
			_edges.set_cell(cell, 0, at)
		var corners := _corner_mask(bytes, cell, int(bytes[idx]), turned)
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
##
## `turned` holds the lawn cells the hoe has turned (task 0167), by index:
## the terrain byte under them is still grass, but no grass creeps in from
## them, so a starter bed meets the plot beside it without a green seam.
static func _edge_tile(bytes: PackedByteArray, cell: Vector2i,
		terrain: int, turned: Dictionary = {}) -> Vector2i:
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
			else theirs == Farm.Terrain.GRASS and not turned.has(Grid.index(at))
		if edged:
			mask |= 1 << bit
	return Vector2i(-1, -1) if mask == 0 else Vector2i(mask, row)


## A diagonal cap fills only an exposed elbow: neither adjoining cardinal
## side can already draw an edge. It reads terrain without changing any state.
static func _corner_mask(bytes: PackedByteArray, cell: Vector2i, terrain: int,
		turned: Dictionary = {}) -> int:
	if terrain == Farm.Terrain.GRASS:
		return 0
	var at := _edge_tile(bytes, cell, terrain, turned)
	var cardinal := maxi(0, at.x)
	var mask := 0
	for corner in 4:
		if cardinal & CORNER_CARDINALS[corner]:
			continue
		var diagonal: Vector2i = cell + CORNER_NEIGHBOURS[corner]
		if not Grid.in_bounds(diagonal):
			continue
		var theirs := int(bytes[Grid.index(diagonal)])
		var touches := theirs != Farm.Terrain.WATER if terrain == Farm.Terrain.WATER \
			else theirs == Farm.Terrain.GRASS and not turned.has(Grid.index(diagonal))
		if touches:
			mask |= 1 << corner
	return mask


func _refresh() -> void:
	for sprite in _sprites:
		sprite.queue_free()
	_sprites.clear()
	_stations.clear()
	_tarped.clear()
	_decoys.clear()
	_ambient_materials.clear()
	if _season != null:
		_season.forget_sprites()
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
		if _stand_in_prop(id, int(idx), cell, anchor):
			continue
		var footprint := Building.bounds_at(_state, cell).size if Building.size_of(id) != Vector2i.ONE else Vector2i.ONE
		# A gathering node in its struck state (task 0177): A021's chipped big
		# stump from the first swing (task 0204).
		var drawn := struck_art(_state, id, anchor) if Gathering.is_node(id) else _station_art(id, on, anchor)
		var whole := _texture_for(drawn)
		var grouped := footprint != Vector2i.ONE and (PlaceholderArt.has_frame(whole.resource_path)
			or (whole.get_width() >= footprint.x * GameData.TILE_SIZE
			and whole.get_height() >= footprint.y * GameData.TILE_SIZE))
		if grouped and cell != anchor:
			continue
		var sprite := Sprite2D.new()
		sprite.name = "Prop_%d" % idx
		sprite.texture = whole if grouped else _texture_for(_art_for(on, cell))
		ArtPlacement.place(sprite, anchor if grouped else cell, footprint if grouped else Vector2i.ONE)
		# **Frosted while it is chilled** (task 0251): on `self_modulate`,
		# because `Transition` owns a tower's `modulate` - the guns' flare at
		# dusk, every frame.
		sprite.self_modulate = chill_tint(_state, cell)
		var logical_cells: Array = []
		if grouped:
			for y in footprint.y:
				for x in footprint.x:
					var part := Grid.index(anchor + Vector2i(x, y))
					if occupants.has(part) and occupants[part].get("id", &"") == id:
						logical_cells.append(part)
		else:
			logical_cells.append(idx)
		sprite.set_meta("logical_cells", logical_cells)
		if grouped and Gathering.is_node(id):
			sprite.set_meta("prop_art", drawn)
		# **Under a tarp by day** (task 0223), dressed as it is made, so a
		# rebuild never shows a sleeping tower bare for a frame.
		if tarps and Transition.TARPS.has(id):
			_tarp(sprite, StringName(Transition.TARPS[id]), _is_hurt(on))
		# **A tree in its season** (task 0159): A013's frame for it when there
		# is one, remapped unless it is the real thing.
		var remapped := true
		if id == &"tree":
			var art := "props/" + str(_art_for(on, cell))
			var seasonal := SeasonView.frame_for(art, _season.season())
			if seasonal != art:
				sprite.texture = _texture_at(SeasonView.texture_file(seasonal))
			remapped = not SeasonView.carries_season(art, _season.season())
		if id in [&"tree", &"chicken", &"cow"]:
			var motion := ShaderMaterial.new()
			motion.shader = AMBIENT_MOTION
			_season.dress(motion, id == &"tree" and remapped)
			motion.set_shader_parameter("species", 0 if id == &"tree" else (1 if id == &"chicken" else 2))
			motion.set_shader_parameter("phase", float((cell.x * 37 + cell.y * 19) % 101) * 0.13)
			if id == &"tree":
				var wind_seed := ((cell.x + 1) * 73856093) ^ ((cell.y + 1) * 19349663)
				motion.set_shader_parameter("wind_speed", 0.55 + float(wind_seed % 97) / 96.0 * 0.4)
				motion.set_shader_parameter("wind_strength", 0.65 + float((wind_seed / 97) % 89) / 88.0 * 0.3)
			motion.set_shader_parameter("motion_time", _ambient_time)
			sprite.material = motion
			_ambient_materials.append(motion)
		# **Snow on the roofs** (task 0159): the top edge of the farmhouse,
		# the stall and the stations - the whole drawing, or its top quarters.
		if id in SeasonView.ROOFED and (grouped or cell.y == anchor.y):
			sprite.material = _season.roof_material()
		# The stall, which the peddler's hours shut and open (task 0190).
		if id == &"shop" and grouped and _peddler_view != null:
			_peddler_view.set_stall(sprite)
		if _season.season() == SeasonView.WINTER and id in SeasonView.CAPPED:
			_cap(sprite, _art_for(on, cell), footprint != Vector2i.ONE)
		# Every station with a recipe (the keg and the jar since task 0187).
		if Crafting.is_station(id) or id == &"generator":
			sprite.set_meta("station_id", id)
			sprite.set_meta("station_anchor", anchor)
			_stations.append(sprite)
		# A decoy, which sways when it is struck (task 0224).
		if id == &"decoy":
			_decoys[int(idx)] = sprite
		if id == &"tree":
			var shadow := Sprite2D.new()
			shadow.texture = load(PlayerView.SHADOW)
			shadow.position.y = -1.0
			shadow.modulate.a = PlayerView.SHADOW_ALPHA
			shadow.show_behind_parent = true
			sprite.add_child(shadow)
		# Pressure discs lie under boots, never paint over an actor's legs -
		# and so does a bait (task 0225), with a crowd stood on it eating.
		# A braid stands up among them (task 0228): only a flat thing lies under.
		if id == &"mine" or (GameData.DEFENCES.has(id) and Building.walked_over(id) and lies_flat(id)):
			_ground_traps.add_child(sprite)
		else:
			_occupants.add_child(sprite)
		_sprites.append(sprite)
		# Complete authored levels communicate their reinforcement themselves,
		# and so does a joined barrier's (task 0231's hardwood wall).
		var pips := 0 if authored_tower(id) or connected_barrier(id) else maxi(int(on.get("level", 1)) - 1, 0)
		for pip in pips:
			var mark := ColorRect.new()
			mark.color = Color(1.0, 0.86, 0.42, 0.95)
			mark.position = Vector2(cell) * float(GameData.TILE_SIZE) 				+ Vector2(2.0 + pip * 4.0, 1.0)
			mark.size = Vector2(3.0, 3.0)
			_occupants.add_child(mark)
			_sprites.append(mark)


## **A map prop whose pack has not landed** (task 0156: A021's copper, coal
## and gold nodes and the hardwood stump; since 0183 A030's coop and barn),
## drawn through 0120's road: the
## stand-in's texture, tinted and scaled as its `ART` entry says, once over
## the thing's whole footprint at its anchor. False for anything with real
## art or no entry, which the loop draws as it always has.
func _stand_in_prop(id: StringName, idx: int, cell: Vector2i, anchor: Vector2i) -> bool:
	var entry := PlaceholderArt.art(id)
	# A building's too since task 0183: A030's coop and barn.
	if entry.is_empty() or not str(entry.get("dir", "")) in [PROP_DIR, BUILDING_DIR]:
		return false
	var path := PlaceholderArt.art_path(id, 0)
	var file := PlaceholderArt.texture_path(path)
	if file == path or file.is_empty():
		return false            # the real art is here, or it is drawn by code
	if cell != anchor:
		return true             # one drawing over the whole footprint
	# **Chipped once the axe has bitten** (task 0177): the pack's second
	# state, until the last swing takes the whole thing down. A coop or a
	# barn hurt or wrecked (task 0186) wears its state's art, and a keg or a
	# jar (task 0187) its working one too.
	var art := struck_art(_state, id, anchor)
	if Building.wrecks(id):
		art = _worn_stand_in(id, Farm.occupant(_state, anchor))
	if Crafting.is_station(id):
		art = _stand_in_station_art(id, Farm.occupant(_state, anchor), anchor)
	# **A stand-in tower** (task 0226's hive, until A038): its level's
	# stand-in, lit as it stings and hurt past the wear threshold.
	if stand_in_tower(id):
		art = _stand_in_tower_art(Farm.occupant(_state, anchor))
	if art != id:
		file = PlaceholderArt.texture_path(PlaceholderArt.art_path(art, 0))
	var sprite := Sprite2D.new()
	sprite.name = "Prop_%d" % idx
	sprite.texture = load(file)
	sprite.set_meta("prop_art", art)
	ArtPlacement.place(sprite, anchor, Building.size_of(id))
	sprite.scale *= PlaceholderArt.art_scale(art)
	# The stand-in's own tint only: A013's snow cap (task 0164) is a child of
	# the node and stays snow on a copper, coal or gold stand-in. A stand-in
	# tower frosted while it is chilled too (task 0251).
	sprite.self_modulate = PlaceholderArt.art_tint(art) * chill_tint(_state, anchor)
	if _season != null and _season.season() == SeasonView.WINTER and id in SeasonView.CAPPED:
		_cap(sprite, id, Building.size_of(id) != Vector2i.ONE)
	var logical_cells: Array = []
	var size := Building.size_of(id)
	for y in size.y:
		for x in size.x:
			logical_cells.append(Grid.index(anchor + Vector2i(x, y)))
	sprite.set_meta("logical_cells", logical_cells)
	# **A stand-in station changes with its work** (task 0187): the keg and
	# the jar join the stations the frame's refresh looks at.
	if Crafting.is_station(id):
		sprite.set_meta("station_id", id)
		sprite.set_meta("station_anchor", anchor)
		sprite.set_meta("stand_in", true)
		_stations.append(sprite)
	_occupants.add_child(sprite)
	_sprites.append(sprite)
	return true


## A stand-in station's state (task 0187): hurt or wrecked as
## `_worn_stand_in` says, else `<id>_active` while it works, else itself -
## the order `_station_art` keeps for real art, so a damaged machine still
## reads as damaged while it works.
func _stand_in_station_art(id: StringName, on: Dictionary, anchor: Vector2i) -> StringName:
	var worn := _worn_stand_in(id, on)
	if worn != id or not station_running(_state, id, anchor):
		return worn
	var active := StringName("%s_active" % id)
	return active if not PlaceholderArt.art(active).is_empty() or _exists(active) else id


## Whether `id` is a tower drawn through 0120's road (task 0226's hive): a
## defence that shoots - or lights (task 0229's searchlight) - with a stand-in
## where its pack's art will go.
static func stand_in_tower(id: StringName) -> bool:
	var row: Dictionary = GameData.DEFENCES.get(id, {})
	return not authored_tower(id) and (row.has("reload_ticks") or row.has("light_tiles")) \
		and not PlaceholderArt.art(id).is_empty()


## A stand-in tower's state (task 0226): `<id>` or `<id>_<level>`, then
## `_fire` while it has just fired or else `_hurt` past the wear threshold -
## `_worn`'s order for real towers - each only where the registry has it.
func _stand_in_tower_art(on: Dictionary) -> StringName:
	var full := tower_name(on)
	if PlaceholderArt.art(full).is_empty():
		full = StringName(on["id"])
	var lit := StringName("%s_fire" % full)
	# A lamp's `_fire` is its lens lit (task 0229): on at night, at full power.
	var lamp := (GameData.DEFENCES.get(StringName(on["id"]), {}) as Dictionary).has("light_tiles")
	var firing := lamp_at_full(_state) if lamp else just_fired(on)
	if firing and not PlaceholderArt.art(lit).is_empty():
		return lit
	var hurt := StringName("%s_hurt" % full)
	if _is_hurt(on) and not PlaceholderArt.art(hurt).is_empty():
		return hurt
	return full


## A building as the night left it (task 0186; the keg and the jar since
## 0187): `<id>_wreck` at 0 HP, `<id>_hurt` past the wear threshold, itself
## otherwise - each only where the registry or the real art has it.
func _worn_stand_in(id: StringName, on: Dictionary) -> StringName:
	if int(on.get("hp", 1)) <= 0:
		var wreck := StringName("%s_wreck" % id)
		if not PlaceholderArt.art(wreck).is_empty() or _exists(wreck):
			return wreck
	if _is_hurt(on):
		var hurt := StringName("%s_hurt" % id)
		if not PlaceholderArt.art(hurt).is_empty() or _exists(hurt):
			return hurt
	return id


## The art a gathering node is drawn as: `<id>_chipped` from its first swing
## to its last when that state is drawn - A021's big stump (task 0177), raster
## art since task 0204 - and its own otherwise.
static func struck_art(state: Dictionary, id: StringName, anchor: Vector2i) -> StringName:
	var chipped := StringName("%s_chipped" % id)
	if not Gathering.is_node(id) or not PlaceholderArt.has_frame(PROP_DIR + str(chipped) + ".png"):
		return id
	var full := int((GameData.GATHERING[id] as Dictionary)["hits"])
	return chipped if Gathering.swings_left(state, anchor) < full else id


## **A snow cap** (task 0159) over a node in winter: A013's own, or its
## generic one - raster art since task 0164, drawn at the host's canvas
## origin, never stretched. A registered stand-in, if a later host brings
## one, is the host's own frame through the snow mask, the snow alone.
func _cap(host: Sprite2D, art: StringName, two_by_two: bool) -> void:
	var cap := SeasonView.cap_for(art, two_by_two)
	var sprite := Sprite2D.new()
	sprite.name = "SnowCap"
	if SeasonView.stand_in(cap):
		sprite.texture = host.texture
		sprite.material = _season.cap_material()
		sprite.centered = host.centered
		sprite.offset = host.offset
		sprite.region_enabled = host.region_enabled
		sprite.region_rect = host.region_rect
	else:
		# The real cap, at its own size and pivot, over the host's foot.
		sprite.texture = _texture_at(SeasonView.file_of(cap))
		sprite.centered = false
		sprite.offset = -Vector2(PlaceholderArt.frame(SeasonView.file_of(cap)).get("pivot",
			Vector2i(8, 14)))
		sprite.scale = Vector2.ONE / host.scale
	host.add_child(sprite)


## **The ground in its season** (task 0159): the remap on the terrain's
## material - or, where a season has its own atlas (A012's winter, since task
## 0163), that atlas on the tile set and the remap off it. The cells are never
## laid again for it.
func _apply_ground_art() -> void:
	if _season == null or _terrain.tile_set == null:
		return
	var season := _season.season()
	var art := SeasonView.frame_for("terrain/atlas", season)
	_season.ground.set_shader_parameter("remap",
		not SeasonView.carries_season("terrain/atlas", season))
	var file := SeasonView.texture_file(art)
	if file == _ground_file or not ResourceLoader.exists(file):
		return
	var source := _terrain.tile_set.get_source(0) as TileSetAtlasSource
	if source != null:
		source.texture = load(file)
		_ground_file = file


## How many times the terrain's cells have been laid - for `input_v1`.
func terrain_draws() -> int:
	return _terrain_draws


## The season the farm is drawn in, and its view - for `input_v1`.
func season_view() -> SeasonView:
	return _season


## A texture by file, cached with the rest.
func _texture_at(file: String) -> Texture2D:
	var key := StringName("file:" + file)
	if not _textures.has(key):
		_textures[key] = load(file) if ResourceLoader.exists(file) else null
	return _textures[key]


## World-owned cosmetic time freezes with pause; no clocks enter saved state.
func _refresh_ambient(delta: float) -> void:
	if not ambient_running:
		return
	_ambient_time += maxf(delta, 0.0)
	for material in _ambient_materials:
		material.set_shader_parameter("motion_time", _ambient_time)


## **Task 0129.** He is in bed from the switch to the morning, so the
## farmhouse says so: A002's Zzz rises from the roof. A view cue on the view's
## own clock - not a `Reactions` kind - so no tick and no hash ever sees it.
## Not while he lies where he fell at 02:00: he is not in there yet.
func _refresh_zzz(delta: float) -> void:
	var phase := int(_state["phase"])
	var bounds := Farm.house_bounds(_state)
	var on := House.asleep(_state) and bounds.size != Vector2i.ZERO \
		and (phase == Phases.NIGHT
			or (phase == Phases.PREPARATION and not House.passed_out(_state)))
	_zzz.visible = false
	if not on:
		_zzz_time = 0.0
		return
	if ambient_running:
		_zzz_time += maxf(delta, 0.0)
	var strip := PlayerArt.animation(&"react_zzz")
	var frames := maxi(int(strip.get("frames", 1)), 1)
	var each := maxf(float(strip.get("seconds", 0.4)), 0.01)
	var frame := int(_zzz_time / each) % frames
	# The glyph's own crop, as the farmer's reactions are drawn: the stand-in's
	# until A002 lands, then each frame's own.
	var file := PlaceholderArt.texture_path("%sreact_zzz_%d.png" % [PlaceholderArt.DIR, frame])
	var metadata := PlaceholderArt.frame(file)
	if not metadata.has("bubble"):
		return
	if not _zzz_textures.has(file):
		_zzz_textures[file] = load(file) if ResourceLoader.exists(file) else null
	var box: Rect2i = metadata["bubble"]
	var draw_scale := float(metadata.get("draw_scale", 1.0))
	var tile := float(GameData.TILE_SIZE)
	var corner := Vector2(bounds.position) * tile
	var middle := corner.x + float(bounds.size.x) * tile * 0.5
	var chimney := ArtPlacement.emission(&"house", corner, &"smoke",
		Vector2(middle, corner.y), bounds.size)
	# On the middle of the roof, its lowest letter `ZZZ_ON_ROOF` below the
	# chimney's top - over the roof rather than the sky above it, where the
	# night bar sits when the house is at the top of the screen - drifting up
	# a little through each loop.
	var cycle := each * float(frames)
	var rise := ZZZ_RISE * fposmod(_zzz_time, cycle) / cycle
	_zzz.texture = _zzz_textures[file]
	_zzz.region_rect = Rect2(box)
	_zzz.scale = Vector2.ONE * draw_scale
	_zzz.position = Vector2(floorf(middle), floorf(chimney.y + ZZZ_ON_ROOF - rise
		- float(box.size.y) * draw_scale))
	_zzz.visible = _zzz.texture != null


## **The guardian points when a defence goes down** (task 0133), spotted the
## way `sfx.gd` and `particles.gd` spot things: this frame's occupants against
## the last. No `Events` kind, so the hash never hears of it. The first look at
## a state only learns what is there.
## **A decoy sways when it is struck** (task 0224): A037's lean - the top of
## the straw two pixels west, one back east, one west, upright - a tenth of a
## second each, whoever bit it, the stake's foot staying put. Until A037's
## strips land it is the whole drawing leaning (`DecoyArt.lean`). View only:
## it watches the hit points the rules keep and nothing reads it back.
func _sway_decoys(delta: float) -> void:
	var occupants: Dictionary = _state["occupants"]
	for idx in _decoy_hits.keys():
		if not _decoys.has(idx):
			_decoy_hits.erase(idx)
	for idx in _decoys:
		var sprite: Sprite2D = _decoys[idx]
		if not is_instance_valid(sprite):
			continue
		var hp := int((occupants.get(idx, {}) as Dictionary).get("hp", 0))
		var seen: Dictionary = _decoy_hits.get(idx, {"hp": hp, "age": INF})
		seen["age"] = 0.0 if hp < int(seen["hp"]) else float(seen["age"]) + delta
		seen["hp"] = hp
		_decoy_hits[idx] = seen
		sprite.skew = DecoyArt.skew_for(DecoyArt.lean(float(seen["age"])))


## How far into its sway the decoy on a cell is, in seconds - `INF` for one
## standing still - for the asserts.
func decoy_sway_age(cell: Vector2i) -> float:
	return float((_decoy_hits.get(Grid.index(cell), {}) as Dictionary).get("age", INF))


func _watch_defences() -> void:
	var now := {}
	var occupants: Dictionary = _state["occupants"]
	for idx in occupants:
		if GameData.DEFENCES.has(StringName((occupants[idx] as Dictionary).get("id", &""))):
			now[idx] = true
	var fresh := false
	if _defences_known:
		for idx in now:
			if not _defences_seen.has(idx):
				fresh = true
				break
	_defences_seen = now
	_defences_known = true
	if fresh and _guardian != null:
		_guardian.point()


## Whether the Zzz is up over the house - for `input_v1` and the shots.
func zzz_showing() -> bool:
	return _zzz != null and _zzz.visible


## Enemy sprites share the y-sorted layer with the player and trees.
func _refresh_actors(delta: float = 0.0) -> void:
	if _actors == null:
		return
	var ids := Entities.ids(_state)
	# Pool the sprites: a wave is a hundred things moving every frame, and
	# freeing and rebuilding a hundred nodes a frame is the one place this view
	# could plausibly cost something.
	while _actor_sprites.size() < ids.size():
		_actor_sprites.append(_new_enemy_sprite())
	while _actor_sprites.size() > ids.size():
		var spare: Node = _actor_sprites.pop_back()
		spare.queue_free()

	var scale_factor := float(GameData.TILE_SIZE) / float(Player.SUBTILE)
	var heads: Array = []
	for i in ids.size():
		var one := Entities.get_one(_state, int(ids[i]))
		var sprite: Sprite2D = _actor_sprites[i]
		var pose := _pose_of(one)
		sprite.texture = _texture_for(pose)
		# Keep material planes and family silhouettes during the core hurt cue.
		sprite.flip_h = _faces_right(one)
		sprite.modulate = actor_tint(_state, one)
		# **A stand-in's tint** (task 0247's soured walker), white for real art.
		sprite.self_modulate = PlaceholderArt.tint_of(ENEMY_DIR + str(pose) + ".png")
		# **A wraith is faint outside light** (task 0252): the fade shader on
		# its sprite, its presence in the alpha the shader reads - its shadow
		# with it. Every other body solid and plain: the sprites are pooled.
		var fades := Enemies.needs_light(StringName(one["kind"]))
		sprite.material = _wraith_material() if fades else null
		if fades:
			sprite.modulate.a = _presence_of(int(ids[i]),
				Light.lit_now(_state, Entities.cell_of(_state, int(ids[i]))), delta)
		# **Anchored at the feet, not at a tile corner.** An enemy is no
		# longer one tile - motion has transparent clearance around the body - so the
		# old "half a tile back and up" drew them with their shins in the
		# ground and their heads in the next row. Bottom-centre on the cell
		# they occupy is the same rule the player uses, and it is what makes
		# a zombie stand on the tile the rules say it is on.
		sprite.position = ArtPlacement.contact(one["pos"]) + crowd_offset(one)
		# **A flyer in the air is drawn above its point** (task 0249), over
		# everything on the ground - a wall it crosses included - and its
		# shadow left down there under it.
		var lift := flight_lift(_state, one)
		var aloft := Enemies.airborne(_state, int(ids[i]))
		sprite.position.y -= lift
		sprite.z_index = 1 if aloft else 0
		var shadow := sprite.get_node("Shadow") as Node2D
		shadow.position.y = lift - 1.0
		shadow.z_index = -1 if aloft else 0
		# Under a fence there is no body to cast one (task 0250).
		shadow.visible = not Enemies.underground(_state, int(ids[i]))
		var metadata := _enemy_frame(pose, sprite.texture)
		var pivot: Vector2i = metadata.get("pivot",
			Vector2i(sprite.texture.get_width() / 2, sprite.texture.get_height()))
		sprite.offset = -Vector2(pivot)
		if Combat.is_stung(_state, int(ids[i])):
			heads.append(sprite.position - Vector2(0.0, roundf(float(pivot.y) * SWARM_HEIGHT)))
	_place_swarms(heads)
	for id in _heading.keys():
		if not Entities.alive(_state, int(id)):
			_heading.erase(id)
	for id in _presence.keys():
		if not Entities.alive(_state, int(id)):
			_presence.erase(id)


## **How much of a wraith shows now** (task 0252): `wraith_presence` of its
## cell's light, eased there from where it was at `WRAITH_FADE_PER_SECOND` -
## and at once the first time it is drawn, so one does not fade in from
## nothing as it arrives.
func _presence_of(id: int, lit: bool, delta: float) -> float:
	var target := wraith_presence(lit)
	var now := move_toward(float(_presence.get(id, target)), target,
		WRAITH_FADE_PER_SECOND * maxf(delta, 0.0))
	_presence[id] = now
	return now


## **A wraith's presence in light and out of it** (task 0252): solid where a
## tower can aim at it, `WRAITH_FAINT` where it cannot.
static func wraith_presence(lit: bool) -> float:
	return 1.0 if lit else WRAITH_FAINT


## The one material every wraith's fade shares (task 0252).
func _wraith_material() -> ShaderMaterial:
	if _wraith_fade == null:
		_wraith_fade = ShaderMaterial.new()
		_wraith_fade.shader = WRAITH_FADE
	return _wraith_fade


## **How high a flyer is drawn** (task 0249): `FLIGHT_LIFT` in the air,
## coming down over the last tile to the crop it is landing on, nothing
## landed - and nothing for anything that walks. A picture of the height; the
## rules have the crow on its cell all the while.
static func flight_lift(state: Dictionary, one: Dictionary) -> float:
	if not Enemies.flies(StringName(one["kind"])) or one.has("peck"):
		return 0.0
	var aimed := int(one.get("flying_to", -1))
	if aimed < 0:
		return FLIGHT_LIFT
	var goal := Grid.cell(aimed) * Player.SUBTILE + Vector2i(Player.SUBTILE / 2, Player.SUBTILE / 2)
	var apart := absi(goal.x - int(one["pos"][0])) + absi(goal.y - int(one["pos"][1]))
	return FLIGHT_LIFT * clampf(float(apart) / float(Player.SUBTILE), 0.0, 1.0)


## **A flyer's pose** (task 0249), off the rules: landed, its touchdown for
## the first `LANDING_TICKS` and its take-off for the last, pecking between;
## in the air, its wingbeat on the clock. Each loop at its frame's seconds.
static func flyer_pose(state: Dictionary, one: Dictionary) -> StringName:
	var kind: StringName = one["kind"]
	if one.has("peck"):
		var left := int(one["peck"])
		var full := int((GameData.ENEMIES[kind] as Dictionary).get("peck_ticks", 1))
		if left > full - LANDING_TICKS or left <= LANDING_TICKS:
			return StringName("%s_land_0" % kind)
		return StringName("%s_peck_%d" % [kind, _beat(state, one, kind, "peck", 3)])
	return StringName("%s_fly_%d" % [kind, _beat(state, one, kind, "fly", 4)])


## Which of `frames` a loop shows now: its frame's seconds on the clock,
## offset by the body's id so a flock does not beat as one.
static func _beat(state: Dictionary, one: Dictionary, kind: StringName, loop: String, frames: int) -> int:
	var seconds := float(PlaceholderArt.frame(ENEMY_DIR + "%s_%s_0.png" % [kind, loop]).get("seconds", 0.1))
	var each := maxi(roundi(seconds * float(GameData.TICK_HZ)), 1)
	return (int(state["tick"]) / each + int(one.get("id", 0))) % frames


## **A swarm spread for the eye** (task 0248): bodies of a kind that comes
## several at once walk one field onto one cell and one point, and drawn
## there a cluster of six is one rat. Each is drawn `SWARM_SPREAD` off its
## point by its id - a picture, never where the rules have it.
static func crowd_offset(one: Dictionary) -> Vector2:
	if Waves.cluster_of(StringName(one["kind"])) <= 1:
		return Vector2.ZERO
	return SWARM_SPREAD[int(one.get("id", 0)) % SWARM_SPREAD.size()]


## **An enemy pose's geometry** (task 0248): by the runtime path the pose is
## drawn at, which answers for real art, a stand-in's file and a drawing
## alike - a drawn rat has no file of its own to ask - else by the texture.
static func _enemy_frame(pose: StringName, texture: Texture2D) -> Dictionary:
	var frame := PlaceholderArt.frame(ENEMY_DIR + str(pose) + ".png")
	if frame.is_empty() and texture != null:
		frame = PlaceholderArt.frame(texture.resource_path)
	return frame


## **An enemy drawn in code until its pack lands** (task 0248's rat), by its
## runtime path: the frame's drawing, or null. Every enemy drawing answers
## here - the world's actors, `Juice`'s corpse, the forecast's head and the
## checks - and 0249-0252 add theirs.
static func drawn_enemy(path: String) -> Texture2D:
	var drawn := RatArt.texture_at(path)
	# And task 0249's crow, until A048.
	if drawn == null:
		drawn = CrowArt.texture_at(path)
	# And task 0250's digger's mound, until A049.
	if drawn == null:
		drawn = DiggerArt.texture_at(path)
	return drawn


## Which way an enemy faces: a tracked family's motion says; an untracked one
## (task 0247's spitter) faces the tower it spits at, else the way it last
## moved - west, the way the art is drawn, until it has.
func _faces_right(one: Dictionary) -> bool:
	if EnemyMotion.tracks(one["kind"]):
		return _enemy_motion.faces_right(one)
	var id := int(one["id"])
	var x := int(one["pos"][0])
	var was: Array = _heading.get(id, [x, false])
	var right := bool(was[1])
	if x != int(was[0]):
		right = x > int(was[0])
	var aimed := Enemies.spitting_at(_state, id)
	if aimed.x >= 0 and aimed.x != x / Player.SUBTILE:
		right = aimed.x > x / Player.SUBTILE
	_heading[id] = [x, right]
	return right


## The tint an enemy is drawn in: the core's hurt cue, else - since task 0230
## - cold blue while it stands stunned, else none.
static func actor_tint(state: Dictionary, one: Dictionary) -> Color:
	if int(one.get("hurt", 0)) > 0:
		return Color(1.25, 1.12, 1.12)
	if Enemies.is_stunned(state, int(one.get("id", 0))):
		return STUNNED_TINT
	return Color(1, 1, 1)


## **The bees on the stung** (task 0226): A038's swarm round the head of each
## one a hive has stung, for as long as the sting lasts - on the night cues'
## layer, out of the ramp, as a burning one's flames are on the particles':
## a sign of what is hurting it, which the night must not grey out. Pooled.
func _place_swarms(heads: Array) -> void:
	if _swarms == null:
		return
	_swarms.transform = _actors.get_global_transform()
	var bees: Texture2D = HiveArt.swarm(HiveArt.frame_at(_ambient_time)) if not heads.is_empty() else null
	while _swarm_sprites.size() < heads.size():
		var sprite := Sprite2D.new()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_swarms.add_child(sprite)
		_swarm_sprites.append(sprite)
	for i in _swarm_sprites.size():
		var sprite := _swarm_sprites[i]
		sprite.visible = i < heads.size()
		if sprite.visible:
			sprite.texture = bees
			sprite.position = heads[i]


## Bounded source-owned one-shots. Removed core entities stay removed.
func _refresh_deaths(delta: float) -> void:
	if _actors == null:
		return
	if not _state.is_empty() and int(_state["phase"]) == Phases.DAY:
		_enemy_deaths.clear()
	_enemy_deaths.advance(delta)
	while _death_sprites.size() < _enemy_deaths._cues.size():
		var sprite := Sprite2D.new()
		sprite.centered = false
		_actors.add_child(sprite)
		_death_sprites.append(sprite)
	for i in _death_sprites.size():
		var sprite: Sprite2D = _death_sprites[i]
		sprite.visible = i < _enemy_deaths._cues.size()
		if not sprite.visible:
			continue
		var cue: Dictionary = _enemy_deaths._cues[i]
		sprite.texture = _texture_for(EnemyDeaths.pose(cue))
		sprite.position = ArtPlacement.contact([cue["pos"].x, cue["pos"].y])
		sprite.flip_h = bool(cue["right"])
		var metadata: Dictionary = PlaceholderArt.frame(sprite.texture.resource_path)
		sprite.offset = -Vector2(metadata.get("pivot", Vector2i(sprite.texture.get_width() / 2, sprite.texture.get_height())))


## An enemy sprite with its shadow at the feet, for one of the pools.
func _new_enemy_sprite() -> Sprite2D:
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
	return sprite


## The survivors of a lost night walking off at dawn. The rules already took
## them off the farm, so these are pictures and nothing else: no core entity
## is read here, and the pool empties itself once the last has faded.
func _refresh_retreats(delta: float) -> void:
	if _actors == null:
		return
	_enemy_retreats.advance(delta)
	var cues := _enemy_retreats._cues
	while _retreat_sprites.size() < cues.size():
		_retreat_sprites.append(_new_enemy_sprite())
	for i in _retreat_sprites.size():
		var sprite: Sprite2D = _retreat_sprites[i]
		sprite.visible = i < cues.size()
		if not sprite.visible:
			continue
		var cue: Dictionary = cues[i]
		sprite.texture = _texture_for(EnemyRetreats.pose(cue))
		sprite.position = ArtPlacement.contact(EnemyRetreats.position(cue))
		sprite.flip_h = bool(cue["right"])
		sprite.modulate = Color(1, 1, 1, EnemyRetreats.alpha(cue))
		sprite.self_modulate = PlaceholderArt.tint_of(ENEMY_DIR + str(EnemyRetreats.pose(cue)) + ".png")
		# A flyer leaves in the air (task 0249).
		var lift := FLIGHT_LIFT if Enemies.flies(StringName(cue["kind"])) else 0.0
		sprite.position.y -= lift
		(sprite.get_node("Shadow") as Node2D).position.y = lift - 1.0
		var metadata := _enemy_frame(EnemyRetreats.pose(cue), sprite.texture)
		sprite.offset = -Vector2(metadata.get("pivot", Vector2i(sprite.texture.get_width() / 2, sprite.texture.get_height())))


## Shots in the air. Two pixels of bright, which at this resolution is enough
## to follow a line of fire across the farm.
func _draw_shots() -> void:
	if _state.is_empty():
		return
	for shot in (_state["projectiles"] as Array):
		var at := shot_position(shot)
		# **A pumpkin in the air** (task 0227): A039's tumbling shot, lifted
		# on its arc, for a thrower of pumpkins with one to throw. An empty
		# catapult's stone stays the plain dot every shot is.
		if throws_pumpkins(StringName(shot.get("from", &""))) and bool(shot.get("armed", true)):
			var pumpkin := CatapultArt.shot(CatapultArt.frame_at(_ambient_time))
			if pumpkin != null:
				_shots.draw_texture(pumpkin, at - Vector2(4.0, 4.0 + arc_lift(shot)))
				continue
		_shots.draw_rect(Rect2(at - Vector2.ONE, Vector2(2, 2)),
			PaletteData.COLOURS[&"flame_hot"])


## **A spitter's globs in the air** (task 0247): A046's wobble, from the
## mouth to the tower's middle on a low arc (`spit_position`), on the night
## cues' layer.
func _draw_spit() -> void:
	if _state.is_empty():
		return
	var glob := SpitterArt.glob(SpitterArt.frame_at(_ambient_time))
	if glob == null:
		return
	for shot in (_state["enemy_shots"] as Array):
		_spit.draw_texture(glob, spit_position(shot) - Vector2(SpitterArt.glob_pivot()))


## **Where a glob is drawn** (task 0247): where the rules carry it, lifted
## from `SPIT_MOUTH_LIFT` over the spitter's feet to `SPIT_HIT_LIFT` up the
## tower as it goes, and `SPIT_ARC` more at the top of its flight. A
## picture of the spit, never a place the rules know.
static func spit_position(shot: Dictionary) -> Vector2:
	var per := float(GameData.TILE_SIZE) / float(Player.SUBTILE)
	var at := Vector2(float(shot["pos"][0]), float(shot["pos"][1])) * per
	var flight := maxi(int(shot.get("flight", 1)), 1)
	var gone := clampf(1.0 - float(int(shot.get("left", 0))) / float(flight), 0.0, 1.0)
	var lift := lerpf(SPIT_MOUTH_LIFT, SPIT_HIT_LIFT, gone) + 4.0 * SPIT_ARC * gone * (1.0 - gone)
	return Vector2(floorf(at.x), floorf(at.y - lift))


## Whether a defence throws pumpkins (task 0227): its rounds are the crop's.
static func throws_pumpkins(id: StringName) -> bool:
	return Ammo.needed_by(id).has(GameData.PUMPKIN)


## **How high a lobbed pumpkin is over its line** (task 0227): a parabola over
## its flight, `PUMPKIN_ARC` pixels at the top. A picture of the throw, never
## a place the rules know - they carry it straight and land it on its cell.
static func arc_lift(shot: Dictionary) -> float:
	var total := int((GameData.DEFENCES.get(StringName(shot.get("from", &"")), {})
		as Dictionary).get("flight_ticks", 0))
	if total <= 0:
		return 0.0
	var gone := clampf(1.0 - float(int(shot.get("left", 0))) / float(total), 0.0, 1.0)
	return roundf(4.0 * PUMPKIN_ARC * gone * (1.0 - gone))


## **A pumpkin bursts where it lands** (task 0227): each one in the air last
## frame and gone this one - landed, whether by the driver's ticks or a
## skipped stretch - leaves A039's four-frame splat on the cell it was thrown
## at, over the ground and under the night's ramp. Frame to frame, as `Juice`
## finds its landed shots, never a state key. Capped, oldest first. **A
## spitter's glob too** (task 0247): A046's three-frame splat up the tower it
## was spat at, the pumpkins' pool shared, out of the night's tint with the
## globs.
func _refresh_splats(delta: float) -> void:
	if _shots == null or _state.is_empty():
		return
	var night := int(_state["phase"]) == Phases.NIGHT
	var now: Dictionary = {}
	if night:
		for shot in (_state["projectiles"] as Array):
			if throws_pumpkins(StringName(shot.get("from", &""))) and bool(shot.get("armed", true)) \
					and StringName(shot.get("aim", GameData.AIM_GUIDED)) == GameData.AIM_BALLISTIC:
				now[int(shot["id"])] = Vector2i(int(shot["to"][0]), int(shot["to"][1]))
		var ids: Array = _pumpkins.keys()
		ids.sort()
		for id in ids:
			if not now.has(id):
				_splat_at(_pumpkins[id])
	_pumpkins = now
	# **And a spitter's glob, on the tower it was spat at** (task 0247): one
	# in the air last frame and gone this one has landed.
	var globs: Dictionary = {}
	if night:
		for shot in (_state["enemy_shots"] as Array):
			globs["%d:%d" % [int(shot["by"]), int(shot["fired"])]] = Vector2i(int(shot["to"][0]), int(shot["to"][1]))
		var spat: Array = _globs.keys()
		spat.sort()
		for key in spat:
			if not globs.has(key):
				_splat_at(_globs[key], true)
	_globs = globs
	for i in range(_splats.size() - 1, -1, -1):
		var splat: Dictionary = _splats[i]
		splat["age"] = float(splat["age"]) + maxf(delta, 0.0)
		var sprite: Sprite2D = splat["sprite"]
		var spit := bool(splat.get("spit", false))
		var each := SpitterArt.splat_seconds() if spit else CatapultArt.splat_seconds()
		var frame := int(floorf(float(splat["age"]) / each))
		var texture: Texture2D = null
		if night:
			texture = SpitterArt.splat(frame) if spit else CatapultArt.splat(frame)
		if texture == null:
			sprite.queue_free()
			_splats.remove_at(i)
			continue
		sprite.texture = texture


## **A spark where a stun lands** (task 0230): each enemy whose stun is longer
## this frame than the last - a fresh shock, by the driver's ticks or a skipped
## stretch - gets A042's three-frame zap where it bit (`zap_point`), on the
## night cues' layer, out of the ramp: a spark at night has to be the
## brightest thing there. Frame to frame, as the splats are, never a state
## key. Capped, oldest first.
func _refresh_zaps(delta: float) -> void:
	if _zaps == null or _state.is_empty():
		return
	_zaps.transform = _actors.get_global_transform()
	var night := int(_state["phase"]) == Phases.NIGHT
	var now: Dictionary = {}
	if night:
		for id in fresh_stuns(_state, _stunned):
			# **The wire's shock, not the bell's** (task 0233): a stun with no
			# electric fence at the cell it bit plays no spark.
			if shocked_by_wire(_state, Entities.get_one(_state, int(id))):
				_zap_at(zap_point(_state, Entities.get_one(_state, int(id))))
		for id in Entities.ids(_state):
			var left := int(Entities.get_one(_state, int(id)).get("stun", 0))
			if left > 0:
				now[int(id)] = left
	_stunned = now
	var each := ElectricFenceArt.zap_seconds()
	for i in range(_zap_cues.size() - 1, -1, -1):
		var cue: Dictionary = _zap_cues[i]
		cue["age"] = float(cue["age"]) + maxf(delta, 0.0)
		var sprite: Sprite2D = cue["sprite"]
		var texture := ElectricFenceArt.zap(int(floorf(float(cue["age"]) / each))) if night else null
		if texture == null:
			sprite.queue_free()
			_zap_cues.remove_at(i)
			continue
		sprite.texture = texture


## The ids, lowest first, whose stun is longer now than in `before` - a stun
## by id, as `_refresh_zaps` keeps it: the ones a shock has just landed on.
static func fresh_stuns(state: Dictionary, before: Dictionary) -> Array:
	var out: Array = []
	for id in Entities.ids(state):
		var left := int(Entities.get_one(state, int(id)).get("stun", 0))
		if left > int(before.get(int(id), 0)):
			out.append(int(id))
	return out


## **Whether a stun came off the wire** (task 0233): the cell it last bit,
## next to it, holds an electric fence - or its rubble, when the bite that
## shocked it brought the fence down. 0233's bell stops everything with no
## wire anywhere near.
static func shocked_by_wire(state: Dictionary, one: Dictionary) -> bool:
	var bit := int(one.get("chewing", -1))
	var here := Entities.cell_of(state, int(one.get("id", 0)))
	if bit < 0 or Grid.manhattan(Grid.cell(bit), here) != 1:
		return false
	var cell := Grid.cell(bit)
	return StringName(Farm.occupant(state, cell).get("id", &"")) == &"electric_fence" \
		or Farm.rubble_at(state, cell) == &"electric_fence"


## **Where a stun's zap goes**: half way from the enemy's feet to the cell it
## bit - the wire it touched - at the wires' height, `ZAP_LIFT` over the
## ground; over its feet when what stunned it was not a bite next to it.
static func zap_point(state: Dictionary, one: Dictionary) -> Vector2:
	var lift := Vector2(0.0, ZAP_LIFT)
	var feet := ArtPlacement.contact(one["pos"]) - lift
	var bit := int(one.get("chewing", -1))
	var here := Entities.cell_of(state, int(one.get("id", 0)))
	if bit < 0 or Grid.manhattan(Grid.cell(bit), here) != 1:
		return feet
	var wire := (Vector2(Grid.cell(bit)) + Vector2(0.5, 1.0)) * float(GameData.TILE_SIZE) - lift
	return (feet + wire) * 0.5


func _zap_at(at: Vector2) -> void:
	if _zap_cues.size() >= ZAP_CAP:
		(_zap_cues[0]["sprite"] as Sprite2D).queue_free()
		_zap_cues.remove_at(0)
	var sprite := Sprite2D.new()
	sprite.name = "Zap"
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture = ElectricFenceArt.zap(0)
	sprite.offset = -Vector2(ElectricFenceArt.zap_pivot())
	sprite.position = at.round()
	_zaps.add_child(sprite)
	_zap_cues.append({"sprite": sprite, "age": 0.0})


## A splat on `cell`: a pumpkin's on the ground, or - `spit`, task 0247 - a
## glob's up the tower it was spat at, where its flight ended.
func _splat_at(cell: Vector2i, spit: bool = false) -> void:
	if _splats.size() >= SPLAT_CAP:
		(_splats[0]["sprite"] as Sprite2D).queue_free()
		_splats.remove_at(0)
	var sprite := Sprite2D.new()
	sprite.name = "SpitSplat" if spit else "PumpkinSplat"
	sprite.centered = false
	sprite.texture = SpitterArt.splat(0) if spit else CatapultArt.splat(0)
	sprite.offset = -Vector2(SpitterArt.splat_pivot() if spit else CatapultArt.splat_pivot())
	sprite.position = (Vector2(cell) + Vector2(0.5, 0.75)) * float(GameData.TILE_SIZE)
	if spit:
		sprite.position.y -= SPIT_HIT_LIFT
	sprite.self_modulate = Color.WHITE if spit else CatapultArt.splat_tint()
	(_spit if spit else _shots).add_child(sprite)
	_splats.append({"sprite": sprite, "age": 0.0, "spit": spit})


static func authored_tower(id: StringName) -> bool:
	return bool((PlaceholderArt.frame(BUILDING_DIR + str(id) + ".png") as Dictionary).get("tower", false))


static func tower_name(on: Dictionary, suffix: String = "") -> StringName:
	var level := maxi(int(on.get("level", 1)), 1)
	return StringName(str(on["id"]) + ("_%d" % level if level > 1 else "") + suffix)


static func tower_muzzles(on: Dictionary, cell: Vector2i) -> Array[Vector2]:
	var tile := float(GameData.TILE_SIZE)
	var fallback := (Vector2(cell) + Vector2(0.8, -0.2)) * tile
	return ArtPlacement.emissions(tower_name(on, "_fire"), Vector2(cell) * tile,
		&"muzzles", fallback, &"muzzle")


## Every fixed tick is observed, including several ticks between rendered frames.
## A newborn core shot still sits at its exact logical firing-cell center.
func before_tick(state: Dictionary) -> void:
	if not is_same(_state, state):
		return
	_observing_tick = true
	_enemy_deaths.before_tick(state, _enemy_motion)
	_enemy_retreats.before_tick(state, _enemy_motion)
	_enemy_motion.before_tick(state)
	_mine_before.clear()
	if int(state["grid_version"]) != _mine_grid_version:
		_mine_grid_version = int(state["grid_version"])
		_mine_cells = Farm.cells_with(state, &"mine")
	for cell in _mine_cells:
		_mine_before[Grid.index(cell)] = Farm.rubble_at(state, cell)
	_mine_sprung_before = Traps.sprung(state)
	_mine_tick_before = int(state["tick"])
	_mine_losses_before = {} if _mine_before.is_empty() else _mine_losses(state)
	var intent: Dictionary = state["intent"]
	var sell_at: Array = intent.get("build_cell", [-1, -1])
	_mine_selling = Grid.index(Vector2i(int(sell_at[0]), int(sell_at[1]))) if bool(intent.get("build_sell", false)) and not bool(intent.get("build_upgrade", false)) else -1
	_remember_towers(state)
	_shot_before.clear()
	for shot in (state["projectiles"] as Array):
		_shot_before[int(shot["id"])] = true


func after_tick(state: Dictionary) -> void:
	if not is_same(_state, state) or not _observing_tick:
		return
	_observing_tick = false
	_enemy_deaths.after_tick(state)
	_enemy_retreats.after_tick(state)
	_enemy_motion.after_tick(state)
	_observe_mines(state)
	var alive: Dictionary = {}
	var barrels: Dictionary = {}
	var per := float(GameData.TILE_SIZE) / float(Player.SUBTILE)
	for shot in (state["projectiles"] as Array):
		var id := int(shot["id"])
		alive[id] = true
		var at := Vector2(float(shot["pos"][0]), float(shot["pos"][1])) * per
		if _shot_origins.has(id):
			var known: Dictionary = _shot_origins[id]
			known["travel"] = float(known["travel"]) + at.distance_to(known["last"])
			known["last"] = at
		elif not _shot_before.has(id):
			var cell := Vector2i(int(shot["pos"][0]) / Player.SUBTILE,
				int(shot["pos"][1]) / Player.SUBTILE)
			var on := Farm.occupant(state, cell)
			if on.is_empty():
				on = _tower_history.get(Grid.index(cell), {})
			if on.is_empty() or on["id"] != shot["from"] or not authored_tower(on["id"]):
				continue
			var points := tower_muzzles(on, cell)
			var ordinal := int(barrels.get(Grid.index(cell), 0))
			barrels[Grid.index(cell)] = ordinal + 1
			var target := Entities.position(state, int(shot["target"]))
			var destination := Vector2(target) * per
			_shot_origins[id] = {"start": at, "muzzle": points[ordinal % points.size()],
				"last": at, "travel": 0.0, "distance": maxf(at.distance_to(destination), 1.0),
				"left": maxi(int(shot.get("left", 0)), 1)}
	for id in _shot_origins.keys():
		if not alive.has(id):
			_shot_origins.erase(id)
	_shot_before.clear()
	_remember_towers(state)


func _observe_mines(state: Dictionary) -> void:
	var consumed := maxi(Traps.sprung(state) - _mine_sprung_before, 0)
	var losses: Dictionary = {} if consumed <= 0 else _mine_losses(state)
	var keys := _mine_before.keys()
	# Occupancy indices are integer cell keys, so numeric ordering is stable.
	keys.sort()
	var candidates: Array = []
	for idx in keys:
		var cell := Grid.cell(int(idx))
		# Old rubble survives a rearm. The existing structure_lost receipt,
		# rather than that old ground mark, distinguishes new destruction.
		var prior := int(_mine_losses_before.get(idx, 0)) if int(state["tick"]) == _mine_tick_before else 0
		if idx == _mine_selling or not Farm.occupant(state, cell).is_empty() or int(losses.get(idx, 0)) > prior:
			continue
		if Farm.rubble_at(state, cell) == &"mine" and _mine_before[idx] != &"mine":
			continue
		candidates.append(idx)
	# If an outside/unobserved removal makes the count ambiguous, do not
	# invent which disc exploded. Normal core consumption has an exact match.
	if candidates.size() != consumed:
		candidates.clear()
	for idx in candidates:
		var cell := Grid.cell(int(idx))
		if _mine_cues.size() >= MINE_CUE_CAP and not _mine_cues.has(idx):
			var oldest: int = _mine_cues.keys()[0]
			(_mine_cues[oldest]["sprite"] as Sprite2D).queue_free()
			_mine_cues.erase(oldest)
		if _mine_cues.has(idx):
			(_mine_cues[idx]["sprite"] as Sprite2D).queue_free()
		var sprite := Sprite2D.new()
		sprite.name = "TriggeredMine_%d" % idx
		sprite.texture = _texture_for(&"mine_triggered")
		_ground_traps.add_child(sprite)
		ArtPlacement.place(sprite, cell)
		_mine_cues[idx] = {"sprite": sprite, "left": MINE_TRIGGER_SECONDS + MINE_SPENT_SECONDS}
	_mine_before.clear()
	_mine_losses_before.clear()


func _mine_losses(state: Dictionary) -> Dictionary:
	var losses: Dictionary = {}
	for event in Events.recent(state):
		if event["kind"] != &"structure_lost" or int(event["tick"]) != int(state["tick"]) or event.get("id", &"") != &"mine":
			continue
		var pair: Array = event["cell"]
		var idx := Grid.index(Vector2i(int(pair[0]), int(pair[1])))
		losses[idx] = int(losses.get(idx, 0)) + 1
	return losses


func _process_mine_cues(delta: float) -> void:
	for idx in _mine_cues.keys():
		var cue: Dictionary = _mine_cues[idx]
		cue["left"] = float(cue["left"]) - maxf(delta, 0.0)
		var sprite: Sprite2D = cue["sprite"]
		var cell := Grid.cell(int(idx))
		if float(cue["left"]) <= 0.0 or int(_state["phase"]) == Phases.DAY or not Farm.occupant(_state, cell).is_empty():
			sprite.hide()
			sprite.queue_free()
			_mine_cues.erase(idx)
			continue
		sprite.texture = _texture_for(&"mine_triggered" if float(cue["left"]) > MINE_SPENT_SECONDS else &"mine_spent")


func _clear_mine_cues() -> void:
	for cue in _mine_cues.values():
		(cue["sprite"] as Sprite2D).queue_free()
	_mine_cues.clear()


## Only the visual launch is displaced; the offset fades along the real flight.
## Mature shots loaded from a save have no guessed launch and use core positions.
func shot_position(shot: Dictionary) -> Vector2:
	var per := float(GameData.TILE_SIZE) / float(Player.SUBTILE)
	var at := Vector2(float(shot["pos"][0]), float(shot["pos"][1])) * per
	var known: Dictionary = _shot_origins.get(int(shot["id"]), {})
	if not known.is_empty():
		var remaining := clampf(1.0 - float(known["travel"]) / float(known["distance"]), 0.0, 1.0)
		if StringName(shot.get("aim", GameData.AIM_GUIDED)) == GameData.AIM_BALLISTIC:
			remaining = clampf(float(shot["left"]) / float(known["left"]), 0.0, 1.0)
		at += (known["muzzle"] as Vector2 - known["start"] as Vector2) * remaining
	return Vector2(floorf(at.x), floorf(at.y))


func _remember_towers(state: Dictionary) -> void:
	# Morning removes rubble without changing the occupancy version.
	var version: int = [int(state.get("grid_version", 0)), (state.get("rubble", {}) as Dictionary).hash()].hash()
	if version == _tower_version:
		return
	_tower_version = version
	var occupants: Dictionary = state["occupants"]
	var rubble: Dictionary = state.get("rubble", {})
	for idx in _tower_history.keys():
		var on: Dictionary = occupants.get(idx, {})
		if on.is_empty() and StringName(rubble.get(idx, &"")) == StringName(_tower_history[idx]["id"]):
			continue
		_tower_history.erase(idx)
	for idx in occupants:
		var on: Dictionary = occupants[idx]
		# A levelled barrier's too (task 0231): the hardwood wall falls to its
		# own wreck.
		if authored_tower(on["id"]) or stand_in_tower(on["id"]) or GameData.TOWER_LEVELS.has(StringName(on["id"])):
			_tower_history[idx] = {"id": on["id"], "level": maxi(int(on.get("level", 1)), 1)}


func _refresh_wrecks() -> void:
	if _wrecks == null or _state.is_empty():
		return
	var signature: int = [(_state.get("rubble", {}) as Dictionary).hash(),
		int(_state.get("grid_version", 0)), _tower_history.hash()].hash()
	if signature == _wreck_signature:
		return
	_wreck_signature = signature
	var visible: Dictionary = {}
	for cell in Farm.rubble_cells(_state):
		var id := Farm.rubble_at(_state, cell)
		var stand_in := stand_in_tower(id)
		if (not authored_tower(id) and not stand_in and id not in [&"wall", &"fence", &"barricade", &"mine", &"decoy", &"electric_fence", &"sandbag_wall"]) or not Farm.occupant(_state, cell).is_empty():
			continue
		var idx := Grid.index(cell)
		visible[idx] = true
		# The save format stores only the family. A fresh view honestly uses L1.
		var remembered: Dictionary = _tower_history.get(idx, {"id": id, "level": 1})
		var sprite: Sprite2D = _wreck_sprites.get(idx)
		if sprite == null:
			sprite = Sprite2D.new()
			sprite.name = "Wreck_%d" % idx
			_wrecks.add_child(sprite)
			_wreck_sprites[idx] = sprite
		# A levelled barrier's wreck at the level it stood at (task 0231's
		# hardwood wall), as a tower's is.
		var wreck_name := tower_name(remembered, "_wreck") if authored_tower(id) or stand_in \
			or GameData.TOWER_LEVELS.has(id) else StringName(str(id) + "_wreck")
		# A stand-in tower's wreck (task 0226's hive) is its registry entry's
		# file, tinted and scaled as the standing one is.
		if stand_in and not PlaceholderArt.art(wreck_name).is_empty():
			sprite.texture = load(PlaceholderArt.texture_path(PlaceholderArt.art_path(wreck_name, 0)))
		else:
			sprite.texture = _texture_for(&"mine_spent" if id == &"mine" else wreck_name)
		ArtPlacement.place(sprite, cell)
		sprite.scale *= PlaceholderArt.art_scale(wreck_name)
		sprite.self_modulate = PlaceholderArt.art_tint(wreck_name)
	for idx in _wreck_sprites.keys():
		if not visible.has(idx):
			(_wreck_sprites[idx] as Sprite2D).hide()
			(_wreck_sprites[idx] as Sprite2D).queue_free()
			_wreck_sprites.erase(idx)


## Turned earth, and the crop on it at whatever stage it has reached.
func _refresh_plots() -> void:
	for sprite in _plot_sprites:
		sprite.queue_free()
	_plot_sprites.clear()
	if _state.is_empty() or _plots == null:
		return

	_relay_edges_for_turned()
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
		# The earth in its season (task 0159): A012's winter plot when it
		# has landed, today's until then.
		var earth := "tilled_wet" if bool(here["watered"]) else "tilled"
		# **Bone meal in the earth** (task 0222): A036's fertilised soil, dry
		# and wet, in every season - the tilled tile paled until 0235.
		if bool(here.get("fertilised", false)):
			_plot_sprite("tilled_fertilised_wet" if bool(here["watered"]) else "tilled_fertilised", cell)
		else:
			var seasonal := SeasonView.frame_for("crops/" + earth,
				_season.season() if _season != null else 0)
			_plot_sprite(earth if SeasonView.stand_in(seasonal) else seasonal.get_file(), cell)

		if Farm.terrain_at(_state, cell) == Farm.Terrain.GRASS:
			var edges := tilled_edge_mask(_state, cell)
			var corners := tilled_corner_mask(_state, cell)
			for bit in 4:
				if edges & (1 << bit):
					_plot_edge_sprite("tilled_edge_n", cell, bit)
				if corners & (1 << bit):
					_plot_edge_sprite("tilled_edge_corner_nw", cell, bit)

		var crop: StringName = here["crop"]
		if crop != &"":
			var stage := Farming.stage(_state, cell)
			_plot_sprite("%s_regrow" % crop if stage == int(GameData.CROPS[crop]["stages"]) else "%s_%d" % [crop, stage], cell)
		elif here.has("withered"):
			# A crop left behind by the season (0171): A014's withered stalks
			# (task 0197), whatever it was.
			_plot_sprite("withered", cell)
		elif here.has("trampled"):
			# A crop the horde walked through (0155): A014's, pressed into the
			# mud (task 0197).
			_plot_sprite("trampled", cell)


## The lawn cells the hoe has turned: plots on grass, by cell index.
func _turned_grass() -> Dictionary:
	var out := {}
	if _state.is_empty():
		return out
	var bytes: PackedByteArray = _state["terrain"]
	for idx in (_state["plots"] as Dictionary):
		if int(bytes[int(idx)]) == Farm.Terrain.GRASS:
			out[int(idx)] = true
	return out


## **A bed's grass edge follows the hoe** (review of 0167). A starter bed
## draws grass creeping in from every side that is lawn, and lawn the hoe has
## turned is lawn no longer: the cells around a plot that came or went get
## their edge and corners laid again. The terrain's own cells never are, and
## `terrain_draws()` does not count this.
func _relay_edges_for_turned() -> void:
	if _edges == null or _state.is_empty():
		return
	var turned := _turned_grass()
	if turned == _turned_seen:
		return
	var changed: Array = []
	for idx in turned:
		if not _turned_seen.has(idx):
			changed.append(idx)
	for idx in _turned_seen:
		if not turned.has(idx):
			changed.append(idx)
	_turned_seen = turned
	var bytes: PackedByteArray = _state["terrain"]
	var done := {}
	for idx in changed:
		var middle := Grid.cell(int(idx))
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var cell := middle + Vector2i(dx, dy)
				var at := Grid.index(cell)
				if at < 0 or done.has(at):
					continue
				done[at] = true
				var terrain := int(bytes[at])
				var edge := _edge_tile(bytes, cell, terrain, turned)
				if edge.x >= 0:
					_edges.set_cell(cell, 0, edge)
				else:
					_edges.erase_cell(cell)
				var corners := _corner_mask(bytes, cell, terrain, turned)
				var start := CORNER_SHORE_START if terrain == Farm.Terrain.WATER else CORNER_EDGE_START
				for corner in 4:
					if corners & (1 << corner):
						_corners[corner].set_cell(cell, 0, Vector2i(start + corner, ROW_BASE))
					else:
						_corners[corner].erase_cell(cell)


## Turf overlays use N1/E2/S4/W8 and the terrain's concave corner scheme.
## Neighbouring starter beds and plots join without an internal grass seam.
static func tilled_edge_mask(state: Dictionary, cell: Vector2i) -> int:
	var mask := 0
	for bit in 4:
		if _untilled_grass(state, cell + EDGE_NEIGHBOURS[bit]):
			mask |= 1 << bit
	return mask


static func tilled_corner_mask(state: Dictionary, cell: Vector2i) -> int:
	var mask := 0
	var edges := tilled_edge_mask(state, cell)
	for bit in 4:
		if not (edges & CORNER_CARDINALS[bit]) \
				and _untilled_grass(state, cell + CORNER_NEIGHBOURS[bit]):
			mask |= 1 << bit
	return mask


static func _untilled_grass(state: Dictionary, cell: Vector2i) -> bool:
	return Grid.in_bounds(cell) and Farm.terrain_at(state, cell) == Farm.Terrain.GRASS \
		and not Farming.is_tilled(state, cell)


## Rotate the north/NW canvas about the tile's centre. This preserves the
## final 16x16 canvas and (8,16) ground pivot for all four orientations.
func _plot_edge_sprite(art: String, cell: Vector2i, quarter_turns: int) -> void:
	var texture: Texture2D = load(PlaceholderArt.texture_path(CROP_DIR + art + ".png"))
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = Vector2(cell) * GameData.TILE_SIZE + Vector2.ONE * GameData.TILE_SIZE / 2.0
	sprite.rotation = quarter_turns * PI / 2.0
	if _season != null:
		sprite.material = _season.ground
	sprite.set_meta("plot_cell", Grid.index(cell))
	sprite.set_meta("plot_art", art)
	_plots.add_child(sprite)
	_plot_sprites.append(sprite)


## One sprite on one plot. Two of them stack on a watered tile with something
## growing in it, which is why this is a function rather than a block.
func _plot_sprite(art: String, cell: Vector2i) -> void:
	var texture := _crop_texture(art)
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	ArtPlacement.place(sprite, cell)
	var runtime := CROP_DIR + art + ".png"
	var shape := PlaceholderArt.frame(runtime)
	if shape.has("stand_in") and GameData.CROPS.has(StringName(art.get_slice("_", 0))):
		# Existing stages sit at the foot of the final canvas; no pixels are
		# resized or generated. The tall crops have eight transparent rows
		# above the 16x24 corn stand-in in their 16x32 logical canvas.
		sprite.offset = -Vector2(shape["pivot"])
		sprite.modulate = PlaceholderArt.art_tint(StringName(art if art.ends_with("_regrow") else art.get_slice("_", 0)))
	elif shape.has("stand_in"):
		# Earth standing in for earth (task 0222's fertilised soil): the same
		# canvas, its own tint.
		sprite.modulate = PlaceholderArt.art_tint(StringName(art))
	sprite.set_meta("plot_canvas", shape.get("canvas", Vector2i.ZERO))
	sprite.set_meta("plot_cell", Grid.index(cell))
	sprite.set_meta("plot_art", art)
	_plots.add_child(sprite)
	_plot_sprites.append(sprite)


## A crop sprite, cached. A stage the pipeline has not drawn falls back to the
## turned earth rather than to nothing, so a missing frame looks like a missing
## frame instead of like a field that stopped growing.
func _crop_texture(art: String) -> Texture2D:
	var key := StringName("crop/" + art)
	if _textures.has(key):
		return _textures[key]
	var path := PlaceholderArt.texture_path(CROP_DIR + art + ".png")
	if not ResourceLoader.exists(path):
		push_warning("no crop sprite at %s" % path)
		path = CROP_DIR + "tilled.png"
		if not ResourceLoader.exists(path):
			return null
	var texture: Texture2D = load(path)
	var shape := PlaceholderArt.frame(CROP_DIR + art + ".png")
	if shape.has("stand_in") and GameData.CROPS.has(StringName(art.get_slice("_", 0))):
		var padding := int(shape["canvas"].y) - texture.get_height()
		if padding > 0:
			# A transparent margin around existing art, never a new bitmap.
			var padded := AtlasTexture.new()
			padded.atlas = texture
			padded.region = Rect2(Vector2.ZERO, texture.get_size())
			padded.margin = Rect2(0, padding, 0, padding)
			texture = padded
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
	if connected_barrier(id):
		return _barrier_name(on, cell)
	# **A braid as the nights have left it** (task 0228): A040's fresh, wilted
	# or spent.
	if Garlic.repels(id):
		return garlic_art(on)

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
		return _prop_variant(id, cell) if PROP_VARIANTS.has(id) else _worn(id, on)

	var pair: Array = at
	return _worn(StringName("%s_%d_%d" % [id, cell.x - int(pair[0]),
		cell.y - int(pair[1])]), on)


## The drawing a garlic braid wears (task 0228): its id fresh, `_wilted` and
## `_spent` after, by `Garlic.state_of`.
static func garlic_art(on: Dictionary) -> StringName:
	var id := StringName(on["id"])
	match Garlic.state_of(on):
		Garlic.WILTED:
			return StringName("%s_wilted" % id)
		Garlic.SPENT:
			return StringName("%s_spent" % id)
	return id


## **Whether a lamp burns at full** (task 0229): from the sun going down to
## the morning, on a farm with all the power it wants. Short of power its
## light shrinks and its lens shows dark - the cue that it is not at full.
static func lamp_at_full(state: Dictionary) -> bool:
	return not state.is_empty() and int(state["phase"]) != Phases.DAY and not Power.is_short(state)


## Whether a thing's drawing lies on the ground - no taller than a tile - so
## the feet that walk over it are drawn over it (task 0225's bait), rather
## than standing up among them to be sorted with them (task 0228's braid).
static func lies_flat(id: StringName) -> bool:
	var canvas: Vector2i = PlaceholderArt.frame(BUILDING_DIR + str(id) + ".png").get("canvas",
		Vector2i(GameData.TILE_SIZE, GameData.TILE_SIZE))
	return canvas.y <= GameData.TILE_SIZE


static func connected_barrier(id: StringName) -> bool:
	return bool((PlaceholderArt.frame(BUILDING_DIR + str(id) + ".png") as Dictionary).get("connected", false))


## The barriers that join their neighbours: the wall - at any level, the
## hardwood one too - the fence, since task 0230 the electric fence, and
## since 0231 the sandbags. Every one meets every other, so a line is one line
## whatever it is made of: a run of wire carries on a wooden fence, sandbags
## stop a gap between two walls.
const JOINED_BARRIERS: Array[StringName] = [&"wall", &"fence", &"electric_fence", &"sandbag_wall"]


## The same N1/E2/S4/W8 order as terrain. No empty-cell decorative posts;
## adjacent stone/wood/wire barriers meet while unrelated structures stay
## separate.
static func barrier_mask(state: Dictionary, cell: Vector2i) -> int:
	var mask := 0
	for bit in EDGE_NEIGHBOURS.size():
		var at: Vector2i = cell + EDGE_NEIGHBOURS[bit]
		if Grid.in_bounds(at) and JOINED_BARRIERS.has(StringName(Farm.occupant(state, at).get("id", &""))):
			mask |= 1 << bit
	return mask


## A barrier's drawing for its cell: its family at its level - `wall_2`, the
## hardwood wall, since task 0231 - the mask its neighbours make, and hurt.
func _barrier_name(on: Dictionary, cell: Vector2i) -> StringName:
	var mask := barrier_mask(_state, cell)
	var id := str(tower_name(on)) + ("_join_%d" % mask if mask else "")
	return StringName(id + ("_hurt" if _is_hurt(on) else ""))


## Cosmetic source-owned shapes selected by cell, stable through harvesting
## and regrowth. No simulation RNG, tick, occupancy or resource changes.
const PROP_VARIANTS := {
	&"tree": [&"tree", &"tree_b"], &"rock": [&"rock", &"rock_b"],
	&"seam": [&"seam", &"seam_b"], &"ore": [&"ore", &"ore_b"],
	# A021's (task 0204): each forge node's alternate at its master's scale.
	&"copper_ore": [&"copper_ore", &"copper_ore_b"], &"coal_seam": [&"coal_seam", &"coal_seam_b"],
	&"gold_ore": [&"gold_ore", &"gold_ore_b"],
}


static func _prop_variant(id: StringName, cell: Vector2i) -> StringName:
	if not PROP_VARIANTS.has(id):
		return id
	var h := (cell.x * 73856093) ^ (cell.y * 19349663)
	return PROP_VARIANTS[id][1 if absi(h) % 32 >= 24 else 0]


## Read actual running work/fuel; a queued front job waiting on materials is idle.
static func station_running(state: Dictionary, id: StringName, anchor: Vector2i) -> bool:
	if id == &"generator":
		return Power.is_running(state, anchor)
	# Any station with a recipe, and since task 0187 never a wrecked one.
	if not Crafting.is_station(id) or Building.is_wrecked(state, anchor):
		return false
	return Crafting.busy(state, anchor) and not Crafting.is_stalled(state, anchor) \
		and int(Crafting.progress_at(state, anchor)[0]) > 0


## The art a station is drawn as now: its wreck where it stands at 0 HP and
## the wreck is drawn (A031's machines, task 0213), its wear, or its work.
func _station_art(id: StringName, on: Dictionary, anchor: Vector2i) -> StringName:
	if Building.wrecks(id) and int(on.get("hp", 1)) <= 0:
		var wreck := StringName("%s_wreck" % id)
		if _exists(wreck):
			return wreck
	var worn := _worn(id, on)
	# Structural wear stays legible while a damaged station is still working.
	# Real furnace/exhaust effects can still report activity independently.
	if worn != id or not station_running(_state, id, anchor):
		return worn
	var active := StringName("%s_active" % id)
	return active if _exists(active) else worn


func _refresh_stations(delta: float) -> void:
	_station_due -= delta
	if _station_due > 0.0:
		return
	_station_due = 0.12
	for sprite in _stations:
		var anchor: Vector2i = sprite.get_meta("station_anchor")
		var on := Farm.occupant(_state, anchor)
		if on.is_empty():
			continue
		# A stand-in (task 0187) swaps to its state's stand-in and tint; every
		# state of one machine shares its scale.
		if sprite.has_meta("stand_in"):
			var art := _stand_in_station_art(sprite.get_meta("station_id"), on, anchor)
			if art != StringName(sprite.get_meta("prop_art")):
				sprite.set_meta("prop_art", art)
				sprite.texture = load(PlaceholderArt.texture_path(PlaceholderArt.art_path(art, 0)))
				sprite.modulate = PlaceholderArt.art_tint(art)
			continue
		var texture := _texture_for(_station_art(sprite.get_meta("station_id"), on, anchor))
		if sprite.texture != texture:
			sprite.texture = texture


## The same thing at its paid level and existing wear threshold. A damaged
## upgraded tower remains that level; every level owns its matching hurt art.
func _worn(name: StringName, on: Dictionary) -> StringName:
	var level := maxi(int(on.get("level", 1)), 1)
	# **The house's tier is its level** (task 0191): `house_2`, `house_3` and
	# their hurt frames once A035 draws them in 0217, today's house until then.
	if on.get("id", &"") == &"house" and not _state.is_empty():
		level = House.tier(_state)
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
	return just_fired(on)


## Read the same level overlay as Building without a cell lookup or state write
## (`Building.levelled_stat()`, the field's since task 0231).
static func levelled_stat(on: Dictionary, key: String, missing: int = 0) -> int:
	return Building.levelled_stat(on, key, missing)


static func just_fired(on: Dictionary) -> bool:
	var left := int(on.get("reload", 0))
	if left <= 0:
		return false
	# **Against the reload it was given** (task 0251): a chilled tower's is
	# longer, and its flash the same first moment of it - not lit for most of
	# a slow reload, which would read as a tower firing more.
	var whole := levelled_stat(on, "reload_ticks") * 100 / maxi(Towers.reload_speed(on), 1)
	return whole > 0 and left * 100 >= whole * FLASH_PERCENT


## **The frost on a chilled tower** (task 0251): `CHILL_TINT` while a frost
## zombie's burst has it reloading slowly (`Towers.chill_left`) - and the ice
## on a frozen one, `FROZEN_TINT`, while a Winter Lord's cast holds it (task
## 0255, `Towers.frozen_left`) - white otherwise and for anything that is not
## a tower. Tints and no art, as the packs ask.
static func chill_tint(state: Dictionary, cell: Vector2i) -> Color:
	if Towers.frozen_left(state, cell) > 0:
		return FROZEN_TINT
	return CHILL_TINT if Towers.chill_left(state, cell) > 0 else Color.WHITE


## Whether it has taken enough to show it. The same threshold the tint uses,
## so the art and the colour agree about when something looks battered.
func _is_hurt(on: Dictionary) -> bool:
	if on["id"] == &"house":
		return _house_hurt()
	var full := levelled_stat(on, "hp")
	if full <= 0:
		return false
	return float(int(on.get("hp", full))) / float(full) < WOUNDED_AT


func _house_hurt() -> bool:
	return not _state.is_empty() and float(int(_state["house_hp"])) / float(maxi(Phases.house_full(_state), 1)) < WOUNDED_AT


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
	# **Or drawn in code until its pack lands** (task 0224's decoy, hurt as
	# well as whole): art by that name all the same.
	if not found and PlaceholderArt.is_drawn(str(BUILDING_DIR) + str(name) + ".png"):
		found = true
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

	# **An enemy's stand-in** (task 0247's spitter, through 0120's road): the
	# registered stand-in's file - a family's frame, which `tint_of` sours -
	# until its pack lands.
	var stand_in := PlaceholderArt.texture_path(ENEMY_DIR + str(id) + ".png")
	if stand_in != ENEMY_DIR + str(id) + ".png" and ResourceLoader.exists(stand_in):
		var standing: Texture2D = load(stand_in)
		if standing != null:
			_textures[id] = standing
			return standing

	# **Drawn in code until its pack lands** (task 0224's decoy, through
	# 0120's road): `DecoyArt`'s drawing, at the pack's canvas and pivot.
	var coded := DecoyArt.texture(id)
	# And an enemy drawn in code, task 0248's rat, until A047.
	if coded == null:
		coded = drawn_enemy(ENEMY_DIR + str(id) + ".png")
	# And task 0228's garlic braid, `GarlicArt`'s until A040.
	if coded == null:
		coded = GarlicArt.texture(id)
	# And task 0230's electric fence, every mask and the wreck, until A042.
	if coded == null:
		coded = ElectricFenceArt.texture(id)
	# And task 0231's hardwood wall and sandbags, until A043.
	if coded == null:
		coded = StrongWallArt.texture(id)
	if coded != null:
		_textures[id] = coded
		return coded

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


## Authored movement and real wind-up/hit poses are selected by tick observers.
## Removed entities use the separate bounded death pool.
func _pose_of(one: Dictionary) -> StringName:
	var kind: StringName = one["kind"]
	if EnemyMotion.tracks(kind):
		return _enemy_motion.pose(one, _state)
	# **A flyer's poses** (task 0249's crow): in the air, landed, pecking.
	if Enemies.flies(kind):
		return flyer_pose(_state, one)
	# **An untracked kind in the families' pose names** (task 0247's spitter,
	# its stand-in through 0120's road until 0260): played off the rules.
	if PlaceholderArt.has_frame(ENEMY_DIR + "%s_walk_0.png" % kind):
		return posed_off_the_rules(_state, one)
	if int(one.get("winding_at", -1)) >= 0:
		var telegraph := StringName("%s_telegraph" % kind)
		if ResourceLoader.exists(ENEMY_DIR + str(telegraph) + ".png"):
			return telegraph
		return StringName("%s_attack" % kind)
	var beat := (int(_state["tick"]) / ENEMY_WALK_TICKS
		+ int(one.get("id", 0))) % 2
	return kind if beat == 0 else StringName("%s_walk_b" % kind)


## **The pose of an untracked kind drawn in the families' names** (task
## 0247), off the rules alone: spitting, its release and recovery after each
## spit and its rear before the next (`spit_wait`), standing between;
## stunned, standing; else its four steps on the clock, a frame for its walk
## frame's seconds (A046's 0.125, A047's rat 0.1, task 0248) - it walks or it
## chews, and either way it is busy. Under a fence, a digger is its mound
## (task 0250). A charger rears through its wind-up and runs its charge (task
## 0253).
static func posed_off_the_rules(state: Dictionary, one: Dictionary) -> StringName:
	var kind: StringName = one["kind"]
	# **A summoner or a freezer casting** (tasks 0254 and 0255, the Scarecrow
	# King and the Winter Lord): its cast by the cast's progress, a frame for
	# each of its frame's seconds and the last held.
	if (one.has("casting") or one.has("freezing")) and PlaceholderArt.has_frame(ENEMY_DIR + "%s_cast_0.png" % kind):
		var cast_each := maxi(roundi(float(PlaceholderArt.frame(ENEMY_DIR + "%s_cast_0.png" % kind)
			.get("seconds", 0.1)) * float(GameData.TICK_HZ)), 1)
		var cast := int((GameData.ENEMIES[kind] as Dictionary).get("telegraph_ticks", 0)) - int(one.get("chew_wait", 0))
		return StringName("%s_cast_%d" % [kind, clampi(cast / cast_each, 0, 3)])
	# **A charger** (task 0253's Harvester): running its line, its charge on
	# the clock; winding up - for a charge or a blow - rearing, a frame for
	# each of its frame's seconds and the last held.
	if one.has("charge_left") and PlaceholderArt.has_frame(ENEMY_DIR + "%s_charge_0.png" % kind):
		var run_each := maxi(roundi(float(PlaceholderArt.frame(ENEMY_DIR + "%s_charge_0.png" % kind)
			.get("seconds", 0.1)) * float(GameData.TICK_HZ)), 1)
		return StringName("%s_charge_%d" % [kind, (int(state["tick"]) / run_each + int(one["id"])) % 4])
	if Enemies.is_winding(state, int(one["id"])) and PlaceholderArt.has_frame(ENEMY_DIR + "%s_windup_0.png" % kind):
		var rear_each := maxi(roundi(float(PlaceholderArt.frame(ENEMY_DIR + "%s_windup_0.png" % kind)
			.get("seconds", 0.1)) * float(GameData.TICK_HZ)), 1)
		var reared := int((GameData.ENEMIES[kind] as Dictionary).get("telegraph_ticks", 0)) - int(one.get("chew_wait", 0))
		return StringName("%s_windup_%d" % [kind, clampi(reared / rear_each, 0, 2)])
	# **Under a fence, a mound** (task 0250's digger), on its own clock.
	if Enemies.underground(state, int(one["id"])):
		var seconds := float(PlaceholderArt.frame(ENEMY_DIR + "%s_mound_0.png" % kind).get("seconds", 0.125))
		var each := maxi(roundi(seconds * float(GameData.TICK_HZ)), 1)
		return StringName("%s_mound_%d" % [kind, (int(state["tick"]) / each + int(one["id"])) % 3])
	if int(one.get("spitting", -1)) >= 0:
		var every := maxi(int((GameData.ENEMIES[kind] as Dictionary).get("spit_every_ticks", 1)), 1)
		var wait := int(one.get("spit_wait", 0))
		var since := every - wait
		if since < SPIT_RELEASE_TICKS:
			return StringName("%s_attack_1" % kind)
		if since < SPIT_RELEASE_TICKS + SPIT_RECOVER_TICKS:
			return StringName("%s_attack_2" % kind)
		if wait <= SPIT_REAR_TICKS:
			return StringName("%s_attack_0" % kind)
		return kind
	if Enemies.is_stunned(state, int(one["id"])):
		return kind
	var seconds := float(PlaceholderArt.frame(ENEMY_DIR + "%s_walk_0.png" % kind).get("seconds", 0.125))
	var each := maxi(roundi(seconds * float(GameData.TICK_HZ)), 1)
	var step := (int(state["tick"]) / each + int(one["id"])) % 4
	return StringName("%s_walk_%d" % [kind, step])


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
	if Building.entry_of(id) == null:
		return Color.WHITE
	# Against the levelled maximum, like `_is_hurt`: a level three tower at
	# its level one hit points is a tower at half (task 0113).
	var full := levelled_stat(on, "hp")
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

## **A chilled tower's frost** (task 0251): paler, and the blues most - the
## tower as the burst left it. The night's relight drains most of a colour
## and keeps how bright it is, so a frost that only turned it blue was gone by
## the time it reached the screen (the first take); this one is lighter too,
## and still under the night's ramp like everything on the ground.
const CHILL_TINT := Color(1.05, 1.5, 2.3)

## **A frozen tower's ice** (task 0255): whiter than a chill's frost, as the
## tower is held rather than slowed - still under the night's ramp, never lit.
const FROZEN_TINT := Color(1.55, 1.85, 2.5)

## **A freeze's reach on the ground** (task 0255): ice over the square the
## Winter Lord's cast will freeze, faint enough that what stands there shows
## through it, and its edge.
const AURA_GROUND := Color(0.75, 0.9, 1.0, 0.28)
const AURA_EDGE := Color(0.85, 0.95, 1.0, 0.85)

## How much of a reload still has to be left for the muzzle to be lit. High,
## so the flash is a moment rather than a lamp: at 80 a gun on a one second
## reload is lit for about a fifth of a second after each shot.
const FLASH_PERCENT := 80

## How high on a stung thing the swarm hangs (task 0226), as a share of its
## drawing's pivot over its feet: round the head - a walker's is some 24
## pixels up of its 44.
const SWARM_HEIGHT := 0.55

## The garlic's ground under a route preview (task 0228): the bulbs' bone, faint.
const GARLIC_GROUND := Color(0.91, 0.88, 0.81, 0.16)

## How high a lobbed pumpkin rises over its line at the top of its arc, in
## pixels (task 0227), and how many splats burst at once.
const PUMPKIN_ARC := 14.0
const SPLAT_CAP := 8

## **A spitter's glob** (task 0247): it leaves the mouth this high over the
## spitter's feet, lands this high on a tower - its middle - and rises this
## much over its line on the way. Pictures of the spit; the rules carry it
## straight from foot to cell.
const SPIT_MOUTH_LIFT := 22.0
const SPIT_HIT_LIFT := 14.0
const SPIT_ARC := 6.0
## **Its stand-in's poses round a spit** (task 0247), in ticks: the release
## and the recovery after it, and the rear before the next.
const SPIT_RELEASE_TICKS := 3
const SPIT_RECOVER_TICKS := 5
const SPIT_REAR_TICKS := 6

## **How high a crow flies** (task 0249), in pixels over its shadow - A048's
## review flies it over a wall at this - and how many ticks a touchdown and a
## take-off show.
const FLIGHT_LIFT := 10.0
const LANDING_TICKS := 4

## **How a swarm is spread for the eye** (task 0248), in pixels by the body's
## id: within half a rat of its point, so a cluster on one cell reads as a
## crowd of rats round it.
const SWARM_SPREAD := [Vector2(0, 0), Vector2(-6, -2), Vector2(5, -3), Vector2(-3, 3),
	Vector2(7, 1), Vector2(-8, 1), Vector2(2, 4), Vector2(4, -5)]

## **A stunned enemy stands cold blue** (task 0230), and a zap plays where the
## shock landed: at the wires' height over the ground, a few at a time.
const STUNNED_TINT := Color(0.7, 0.88, 1.5)

## **A charge's strip** (task 0253): the warning's red over the cells a
## charger's wind-up has fixed, faint enough that what stands there shows
## through it.
const CHARGE_STRIP := Color(1.0, 0.42, 0.28, 0.55)

## **How much of a wraith shows outside light** (task 0252): faint, never
## gone - the player always knows one is there; it is the towers that cannot
## aim at it. And how fast it comes and goes: a whole fade in a quarter of a
## second.
const WRAITH_FAINT := 0.35
const WRAITH_FADE_PER_SECOND := 4.0
const ZAP_LIFT := 13.0
const ZAP_CAP := 8

## **The farm bell's sound, drawn** (task 0233): this many brass rings at once,
## going out from the house to this many tiles while the bell's mark shows.
const BELL_RINGS := 3
const BELL_REACH := 14.0


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
