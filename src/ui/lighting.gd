class_name Lighting
extends Node2D

## What is burning, drawn as light.
##
## Task 0071 made the night: one tint, one lift, one draining of colour, over
## the whole farm at once. That is the half of the reference sheet that makes
## it *night*. This is the other half - the pools of warm light that make it a
## farm being defended rather than a photograph taken in the dark.
##
## ## Additive glows, above the night ramp
##
## Godot's 2D lights light the canvas items under them, and task 0071's night
## ramp is a screen-space pass that runs after the canvas is drawn - so a
## light under it is a light the ramp then tints blue, which is the one thing
## a fire must not be.
##
## **The first version put them under it anyway**, on the reasoning that the
## ramp already exempts anything brighter than `NIGHT_WARM_KEEP` and a fire is
## bright. That is true of the core of a fire and false of its halo, and the
## halo is most of what a light *is*: the pool on the ground around the
## farmhouse came out as a small yellow dot with a blue-grey smear round it.
## Raising the strength until the pool cleared the threshold only moved the
## dot's edge outward. It was measured and it looked muddy, which is the
## answer.
##
## So this layer sits **over** the relight, where a light is simply a light
## and the ramp is simply the night. That costs one conversion - the layer is
## not carried by the camera, so world positions go through
## `get_canvas_transform()` - and buys a picture that matches the half of the
## reference sheet this task exists to reproduce.
##
## ## It is cosmetic, structurally
##
## Nothing here is read by `src/core/`, nothing here writes to the state, and
## the whole node can be switched off without changing a tick. `input_check`
## asserts that turning it off leaves the outcome of a night alone, which is
## task 0076's own done-when.
##
## ## The quality setting
##
## `video/lights`: 0 off, 1 steady, 2 full. Lights are the thing most likely
## to cost frames on a weak machine, and the honest answer to that is a dial
## rather than a cleverer shader.

enum { OFF, STEADY, FULL }

## How big the glow texture is. One texture, drawn many times at many sizes,
## because a hundred generated gradients is a hundred textures to upload.
const GLOW_SIZE := 64

## Sources, in tiles of radius. Cosmetic, so they live here rather than in
## `game_data`: a purely visual number in the data hash would mean a
## balance-neutral tweak failed the guard.
const HOUSE_RADIUS := 0.9
const STOVE_RADIUS := 2.2
const GENERATOR_RADIUS := 1.6
const MUZZLE_RADIUS := 2.0
const BURNING_RADIUS := 1.3
## A coop's or a barn's lantern by its door (task 0186): small, a light to
## find it by in the dark rather than a room lit up.
const LANTERN_RADIUS := 0.8
const MAX_BURNING_LIGHTS := 12

## What each of them is the colour of. All of them are above task 0071's
## `NIGHT_WARM_KEEP`, which is what keeps them warm after dark.
const HOUSE_COLOUR := Color(1.00, 0.82, 0.46)
const STOVE_COLOUR := Color(1.00, 0.70, 0.34)
const GENERATOR_COLOUR := Color(0.72, 0.88, 1.00)
const MUZZLE_COLOUR := Color(1.00, 0.90, 0.62)
const BURNING_COLOUR := Color(1.00, 0.56, 0.24)
const LANTERN_COLOUR := Color(1.00, 0.80, 0.42)
## The porch guardian's eyes (task 0131): small and warm, two points and never
## a halo over the house.
const EYE_RADIUS := 0.45
const EYE_COLOUR := Color(1.00, 0.78, 0.40)

var _state: Dictionary = {}
var _glow: Texture2D
var _quality := FULL
var _flicker := 0.0
var _window_cores: Array[Vector2] = []
var _eye_cores: Array[Vector2] = []
var _cores: Node2D


func _ready() -> void:
	material = CanvasItemMaterial.new()
	(material as CanvasItemMaterial).blend_mode = \
		CanvasItemMaterial.BLEND_MODE_ADD
	_glow = _build_glow()
	# Tiny opaque amber cores occupy the measured glass, while the existing
	# additive pools stay subdued. Pale cloth is never a light source.
	_cores = Node2D.new()
	_cores.name = "WindowCores"
	_cores.material = CanvasItemMaterial.new()
	(_cores.material as CanvasItemMaterial).blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	add_child(_cores)
	_cores.draw.connect(_draw_window_cores)
	_read_quality()
	var service := get_node_or_null(^"/root/Settings")
	if service != null and not service.changed.is_connected(_on_setting):
		service.changed.connect(_on_setting)
		service.reloaded.connect(_read_quality)


func _on_setting(key: StringName) -> void:
	if key in [&"video/lights", &"a11y/flashing"]:
		_read_quality()
		queue_redraw()


func show_state(state: Dictionary) -> void:
	_state = state


## The quality dial, read the way `TutorialPrompt` reads its flag: by path,
## because `verify.py` parses every script on its own with no autoload
## registered and `Settings.x` is a compile error there.
func _read_quality() -> void:
	# **Asked of the engine, not of this node.** `get_node` with an
	# absolute path errors from outside the active tree, which is
	# every node a headless check builds - task 0102 found it by
	# timing this one, and got an error log instead of a number.
	var loop := Engine.get_main_loop() as SceneTree
	var service: Node = loop.root.get_node_or_null(^"Settings") \
		if loop != null and loop.root != null else null
	if service == null or not service.has_method("get_value"):
		return
	var value: Variant = service.get_value(&"video/lights")
	if value != null:
		_quality = clampi(int(value), OFF, FULL)
	# **`a11y/flashing` already exists and this is a flashing thing.** A
	# player who has turned it off has said they do not want light that
	# moves; `STEADY` is the same lights without the wobble, which is one
	# setting doing what it says rather than two meaning the same.
	var flashing: Variant = service.get_value(&"a11y/flashing")
	if flashing != null and not bool(flashing):
		_quality = mini(_quality, STEADY)


func quality() -> int:
	return _quality


## For `input_check`, which has to be able to turn this off and prove the
## night comes out the same.
func set_quality(level: int) -> void:
	_quality = clampi(level, OFF, FULL)
	queue_redraw()


func _process(delta: float) -> void:
	if _state.is_empty():
		return
	# **The flicker is a wall clock and can only be a wall clock.** It moves
	# the light and nothing else; a tick-driven flicker would be a cosmetic
	# number inside the determinism hash.
	_flicker += delta
	queue_redraw()


func _draw() -> void:
	_window_cores.clear()
	_eye_cores.clear()
	if is_instance_valid(_cores):
		_cores.queue_redraw()
	if _state.is_empty() or _quality == OFF or _glow == null:
		return
	# Daylight needs no lamps. `PREPARATION` counts as night for the same
	# reason the ramp says it does: the sun is down.
	if int(_state.get("phase", Phases.DAY)) == Phases.DAY:
		return

	var tile := float(GameData.TILE_SIZE)
	var occupants: Dictionary = _state["occupants"]
	var keys: Array = occupants.keys()
	# A fixed order, as everything here is. These are cell indices, so they
	# are integers and sort as integers - names would need `sorted_names`.
	keys.sort()

	# Group once per building. The farmhouse emits only at measured glass
	# panes; its nine occupied cells never duplicate those light sources.
	var middles: Dictionary = {}
	for idx in keys:
		var on: Dictionary = occupants[idx]
		var id: StringName = on["id"]
		if not _lights_up(id, on, Grid.cell(int(idx))):
			continue
		var key: Variant = on.get("anchor", null)
		var name := "%s@%s" % [id, str(key) if key != null else str(id)] 			if id == &"house" else "%s@%s" % [id, str(key if key != null
				else Grid.cell(int(idx)))]
		var box: Array = middles.get(name, [id, Vector2.ZERO, 0, Vector2(Grid.cell(int(idx))), on])
		box[1] = (box[1] as Vector2) + Vector2(Grid.cell(int(idx)))
		box[2] = int(box[2]) + 1
		box[3] = Vector2(minf((box[3] as Vector2).x, Grid.cell(int(idx)).x),
			minf((box[3] as Vector2).y, Grid.cell(int(idx)).y))
		middles[name] = box

	for name in GameData.sorted_names(middles.keys()):
		var box: Array = middles[name]
		var id: StringName = box[0]
		var at := ((box[1] as Vector2) / float(box[2]) + Vector2(0.5, 0.5)) 			* tile
		var footprint := Building.bounds_at(_state, Vector2i(box[3])).size
		if id == &"coop" or id == &"barn":
			at = _lantern(Vector2i(box[3]), footprint)
		at = ArtPlacement.emission(id, (box[3] as Vector2) * tile, &"light", at, footprint)
		match id:
			&"house":
				for window in ArtPlacement.emissions(id, (box[3] as Vector2) * tile, &"windows", at, &"light", footprint):
					_window_cores.append(get_viewport().get_canvas_transform()*window)
					_glow_at(window, HOUSE_RADIUS * tile, HOUSE_COLOUR, 0.26)
			&"kitchen", &"workshop":
				_glow_at(at, STOVE_RADIUS * tile, STOVE_COLOUR, 0.70)
			&"generator":
				_glow_at(at, GENERATOR_RADIUS * tile, GENERATOR_COLOUR, 0.45)
			&"coop", &"barn":
				_glow_at(at, LANTERN_RADIUS * tile, LANTERN_COLOUR, 0.55)
				# Its panes once A030 measures them (`windows_xy`). The stand-in
				# has none, and `emissions` would hand the lantern back twice.
				if PlaceholderArt.frame(WorldView.BUILDING_DIR + str(id) + ".png").has("windows"):
					for window in ArtPlacement.emissions(id, (box[3] as Vector2) * tile, &"windows", at, &"light", footprint):
						_glow_at(window, HOUSE_RADIUS * tile, HOUSE_COLOUR, 0.26)
			_:
				if WorldView.authored_tower(id):
					var colour := Color(0.72, 0.88, 1.0) if id == &"auto_crossbow" else MUZZLE_COLOUR
					for muzzle in WorldView.tower_muzzles(box[4], Vector2i(box[3])):
						_glow_at(muzzle, 0.8 * tile, colour, 0.45)
				else:
					_glow_at(at, MUZZLE_RADIUS * tile, MUZZLE_COLOUR, 0.95)

	# **The porch guardian's eyes** (task 0131): a glow on each emission point
	# its lit frames carry, and a one-pixel core so they read through the
	# night's ramp the way the windows do.
	for eye in GuardianView.eyes(_state):
		_eye_cores.append(get_viewport().get_canvas_transform() * eye)
		_glow_at(eye, EYE_RADIUS * tile, EYE_COLOUR, 0.30)

	# **What is on fire.** The one light that moves, and the reason the whole
	# thing is redrawn rather than cached.
	for where in burning_lights():
		_glow_at(where, BURNING_RADIUS * tile, BURNING_COLOUR, 0.22)


## A two-pixel glass core, not a brightness exemption over the roof or farm.
func _draw_window_cores() -> void:
	for at in _window_cores:
		_cores.draw_rect(Rect2(at.floor()-Vector2.ONE,Vector2(2,2)),PaletteData.COLOURS[&"flame_hot"],true)
	for at in _eye_cores:
		_cores.draw_rect(Rect2(at.floor(), Vector2.ONE), PaletteData.COLOURS[&"flame_hot"], true)


## Where the guardian's eye cores were drawn this frame, in screen pixels -
## for the tests.
func eye_cores() -> Array[Vector2]:
	return _eye_cores


## Nearby burning actors share a subdued halo; every actor still keeps its
## actual flame/ember pixels. Additive per-actor lights previously washed a
## dense wave into bright continuous bands. This bounds both glare and draws.
func burning_lights() -> Array[Vector2]:
	var points: Array[Vector2] = []
	if _state.is_empty():
		return points
	var per := float(GameData.TILE_SIZE) / Player.SUBTILE
	var separation := BURNING_RADIUS * GameData.TILE_SIZE * 1.6
	for id in Entities.ids(_state):
		if not Combat.is_burning(_state, int(id)):
			continue
		var one := Entities.get_one(_state, int(id))
		if one.is_empty():
			continue
		var where := Vector2(one["pos"][0],one["pos"][1])*per
		var separate := true
		for point in points:
			if point.distance_to(where)<separation:
				separate = false
				break
		if separate:
			points.append(where)
		if points.size()==MAX_BURNING_LIGHTS:
			break
	return points


## Whether this cell is part of something that is currently lit.
func _lights_up(id: StringName, on: Dictionary, cell: Vector2i) -> bool:
	match id:
		&"house":
			return true
		&"kitchen", &"workshop":
			return WorldView.station_running(_state, id, Building.anchor_of(_state, cell))
		&"generator":
			return WorldView.station_running(_state, id, Building.anchor_of(_state, cell))
		# **The animals' lantern** (task 0186): lit while the coop or the barn
		# stands, whole or hurt, and dark once it is wrecked - A030 draws the
		# wreck with no lantern to light.
		&"coop", &"barn":
			return not Building.is_wrecked(_state, cell)
		_:
			return _firing(on)


## Where a coop's or a barn's lantern hangs until A030's `light_xy` says
## (task 0186): just left of the door - the middle of the front row - at
## about the farmer's head, a tile and a half over the ground line, and never
## above the footprint's top row.
func _lantern(corner: Vector2i, footprint: Vector2i) -> Vector2:
	var door := corner + Vector2i(footprint.x / 2, footprint.y - 1)
	var head := maxf(float(corner.y + footprint.y) - 1.5, float(corner.y) + 0.3)
	return Vector2(float(door.x) - 0.15, head) * float(GameData.TILE_SIZE)


## Whether this is a tower that has just fired. The same question
## `WorldView` asks to choose the muzzle-flash drawing, so the light and the
## picture are lit by the same tick.
func _firing(on: Dictionary) -> bool:
	return WorldView.just_fired(on)


## `at` is in world pixels. This layer is not carried by the camera, so the
## camera has to be applied by hand - which is the price of drawing over the
## night ramp rather than under it.
func _glow_at(at: Vector2, radius: float, colour: Color,
		strength: float) -> void:
	var screen := get_viewport().get_canvas_transform() * at
	radius *= get_viewport().get_canvas_transform().get_scale().x
	var lit := colour
	lit.a = strength
	if _quality == FULL:
		# A small, slow wobble. Enough that a fire is alive and not so much
		# that the farm strobes - `a11y/flashing` turns it off entirely by
		# dropping the quality, which is the setting that exists for it.
		var wobble := 1.0 + 0.08 * sin(_flicker * 7.0 + at.x * 0.7)
		radius *= wobble
		lit.a *= wobble
	draw_texture_rect(_glow,
		Rect2(screen - Vector2(radius, radius), Vector2(radius, radius) * 2.0),
		false, lit)


## A round falloff, computed once.
##
## **Not an ASCII map.** The palette has no partial alpha in it and a glow is
## nothing but partial alpha, so this is the one image in the game that is
## arithmetic rather than a drawing - and it is generated at load rather than
## committed, so there is no PNG for anybody to paint over.
func _build_glow() -> Texture2D:
	var image := Image.create(GLOW_SIZE, GLOW_SIZE, false, Image.FORMAT_RGBA8)
	var middle := float(GLOW_SIZE - 1) * 0.5
	for y in GLOW_SIZE:
		for x in GLOW_SIZE:
			var away := Vector2(float(x) - middle, float(y) - middle).length() \
				/ (float(GLOW_SIZE) * 0.5)
			# Squared falloff, which reads as a lamp rather than as a disc.
			var lit := clampf(1.0 - away, 0.0, 1.0)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, lit * lit))
	return ImageTexture.create_from_image(image)
