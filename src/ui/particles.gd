class_name Particles
extends Node2D

## Fire, smoke, sparks, dust and a little blood.
##
## The difference between a hit and a hit that felt like one, and nothing
## else: **no particle is ever read by `src/core/`, written to the state or
## folded into the hash.** `input_check` plays the same night three times at
## three densities and compares `State.hash_of()`, which is task 0077's own
## done-when.
##
## ## Ambient materials and actual emitters
##
## Smoke, dust, splash and impacts follow the world's ambient ramp. Actual
## muzzle/flame/flare forms and hot sparks use a camera-following layer above
## it. The existing source colours also occur in straw hats and ripe crops,
## so brightness alone must never decide which objects emit warm light.
##
## ## The view notices; the rules do not tell it
##
## There is no "somebody died" signal, and adding one would be putting a
## cosmetic concern into the rules. Instead this keeps its own snapshot of
## what was on the farm last frame and looks at what changed: an entity that
## has gone is a death, an occupant that has gone is a wreck, a fresh `hurt`
## flag is an impact. Missing an event costs a puff of dust and nothing else,
## which is the right price for keeping the state clean.
##
## ## The cap is hard, and it is a setting
##
## A wave is a hundred things dying at once and an uncapped emitter is a
## frame budget with a hole in it. The pool is fixed at `_cap` and the oldest
## particle is reused when it is full, so the cost of a busy night is the same
## as the cost of a quiet one.

## Pixels, in palette colours, never a soft gradient. A particle is one of
## these drawn as a square of one or two pixels.
const SPARK := "flame_hot"
const EMBER := "flame"
const SMOKE := "stone_dark"
const DUST := "soil_light"
const BLOOD := "blood"

## How long each kind lives, in seconds, and how fast it goes.
const LIFE := {
	&"spark": 0.28,
	&"ember": 0.70,
	&"smoke": 1.60,
	&"dust": 0.55,
	&"blood": 0.45,
}

## **Snowfall** (task 0159): flakes a second over whatever the camera sees,
## at full density, in `bone` and `moon`, falling this fast in world pixels a
## second. From the same pool as everything else, so the cap is still a cap
## and the density setting turns the snow down with the rest.
const SNOW_PER_SECOND := 40.0
const SNOW_FALL := Vector2(3.0, 13.0)
const SNOW_COLOURS := [&"bone", &"moon"]

## **The sprinklers' morning** (task 0178): through the first hour of the
## day every sprinkler in view throws this many drops a second at full
## density, out over the cells it waters - the rule watered them at dawn,
## this is only the picture of it. Water's palette, and the same pool.
const SPRAY_PER_SECOND := 40.0
const SPRAY_UNTIL_MINUTE := 7 * 60
const SPRAY_COLOURS := [&"water_light", &"water", &"moon"]
## How long a drop flies, in seconds.
const SPRAY_LIFE := 0.6

## The cap when nothing says otherwise. `video/max_particles` moves it and
## `a11y/particle_density` scales what is asked for - one turns the ceiling
## down and the other turns the tap down, which are different things.
const DEFAULT_CAP := 420

var _state: Dictionary = {}
var _cap := DEFAULT_CAP
var _density := 1.0
var _motion := true
var _forms := PixelEffects.new()
var _burn_cursor := 0
var _warm: Node2D

# The pool. Parallel arrays rather than an array of dictionaries: a hundred
# small dictionaries allocated and freed every second is the one place this
# could plausibly cost something.
var _x: PackedFloat32Array = PackedFloat32Array()
var _y: PackedFloat32Array = PackedFloat32Array()
var _vx: PackedFloat32Array = PackedFloat32Array()
var _vy: PackedFloat32Array = PackedFloat32Array()
var _left: PackedFloat32Array = PackedFloat32Array()
var _span: PackedFloat32Array = PackedFloat32Array()
var _size: PackedByteArray = PackedByteArray()
var _tint: PackedColorArray = PackedColorArray()
## 1 for a snowflake, which falls at its own pace rather than slowing; 2 for
## a sprinkler's drop, which flies at its own pace the same way.
var _falling: PackedByteArray = PackedByteArray()
var _next := 0
var _snow_due := 0.0
var _snow_was := false
## Drops owed to each sprinkler cell, by index.
var _spray_due: Dictionary = {}

# What the farm looked like last frame, so this frame can see what changed.
var _seen_entities: Dictionary = {}
var _seen_occupants: Dictionary = {}
var _smoke_due := 0.0


func _ready() -> void:
	z_index = 15                # over the farm, under task 0076's lights
	z_as_relative = false
	_resize(DEFAULT_CAP)
	# Only semantic fire forms and hot sparks bypass the ambient ramp.
	# Follow the camera through the canvas, preserving the same world pivots.
	var emission_layer := CanvasLayer.new()
	emission_layer.name = "Emissions"
	emission_layer.layer = 2
	emission_layer.follow_viewport_enabled = true
	add_child(emission_layer)
	_warm = Node2D.new()
	_warm.name = "WarmEffects"
	emission_layer.add_child(_warm)
	_warm.draw.connect(_draw_sparks)
	_forms.warm_parent = _warm
	var world := get_parent() as WorldView
	if world != null:
		_forms.ground_parent = world._ground_traps
	_read_settings()
	var service := get_node_or_null(^"/root/Settings")
	if service != null and not service.changed.is_connected(_on_setting):
		service.changed.connect(_on_setting)
		service.reloaded.connect(_read_settings)


func _exit_tree() -> void:
	# Ground forms live below actors in WorldView. Release those reused
	# children too when this emitter leaves the tree.
	_forms.release()


func show_state(state: Dictionary) -> void:
	if not is_same(_state, state):
		_guns_for = -1
		_guns.clear()
		_seen_entities.clear()
		_seen_occupants.clear()
		_smoke_due = 0.0
		_forms.reset()
		for i in _left.size():
			_left[i] = 0.0
	_state = state


func before_tick(state: Dictionary) -> void:
	if is_same(state, _state):
		_forms.before_tick(state, _gun_cells())


func after_tick(state: Dictionary) -> void:
	if is_same(state, _state):
		_forms.after_tick(state)


func _on_setting(key: StringName) -> void:
	if key in [&"video/max_particles", &"a11y/particle_density", &"a11y/flashing"]:
		_read_settings()


## Read by path rather than by name: `verify.py` parses every script on its
## own with no autoload registered, and `Settings.x` is a compile error there.
func _read_settings() -> void:
	# **Asked of the engine, not of this node.** `get_node` with an
	# absolute path errors from outside the active tree, which is
	# every node a headless check builds - task 0102 found it by
	# timing this one, and got an error log instead of a number.
	var loop := Engine.get_main_loop() as SceneTree
	var service: Node = loop.root.get_node_or_null(^"Settings") \
		if loop != null and loop.root != null else null
	if service == null or not service.has_method("get_value"):
		return
	var cap: Variant = service.get_value(&"video/max_particles")
	if cap != null and int(cap) != _cap:
		_resize(maxi(int(cap), 0))
	var density: Variant = service.get_value(&"a11y/particle_density")
	if density != null:
		set_density(float(density))
	var flashing: Variant = service.get_value(&"a11y/flashing")
	if flashing != null:
		set_motion(bool(flashing))


func cap() -> int:
	return _cap


func density() -> float:
	return _density


## For `input_check`, which has to turn these off and prove the night is the
## same without them.
func set_density(value: float) -> void:
	_density = clampf(value, 0.0, 1.0)
	_forms.set_density(_density)
	if _density == 0.0:
		for i in _left.size():
			_left[i] = 0.0


func set_motion(value: bool) -> void:
	_motion = value
	_forms.motion = value


func set_cap(value: int) -> void:
	_resize(maxi(value, 0))


## How many are alive right now. The assert that the cap is a cap.
func live() -> int:
	var n := 0
	for i in _left.size():
		if _left[i] > 0.0:
			n += 1
	return n + _forms.records.size()


func _resize(size: int) -> void:
	_cap = size
	_forms.limit = mini(PixelEffects.MAX_FORMS, size / 4)
	_forms.reset()
	# Raster forms and cheap pixels share one hard ceiling.
	size -= _forms.limit
	# **Each one by name.** A `PackedFloat32Array` is a value type, so
	# `for pool in [_x, _y, ...]` resizes six copies and leaves the six
	# members empty - which fails on the next line rather than quietly, but
	# only because the pool is used immediately.
	_x.resize(size)
	_y.resize(size)
	_vx.resize(size)
	_vy.resize(size)
	_left.resize(size)
	_span.resize(size)
	_size.resize(size)
	_tint.resize(size)
	_falling.resize(size)
	for i in size:
		_left[i] = 0.0
		_falling[i] = 0
	_next = 0


func _process(delta: float) -> void:
	if _state.is_empty():
		return
	_snow(delta)
	_spray(delta)
	_advance(delta)
	_forms.advance(delta, self)
	_watch(delta)
	if is_instance_valid(_warm):
		_warm.transform = get_global_transform()
		_warm.queue_redraw()
	queue_redraw()


## Move what is alive and forget what is not.
##
## **A wall clock, and it can only be a wall clock.** Particles drift on real
## seconds rather than on ticks, so a night played at four times speed has the
## same smoke as one played at one - and so that none of this can reach the
## determinism hash even by accident.
func _advance(delta: float) -> void:
	for i in _left.size():
		if _left[i] <= 0.0:
			continue
		_left[i] -= delta
		if _falling[i] >= 1:
			# A flake keeps its pace and sways a little on the way down; a
			# drop keeps its pace out to where it lands.
			_x[i] += (_vx[i] + sin(_left[i] * 2.3 + float(i)) * 2.0) * delta
			_y[i] += _vy[i] * delta
			continue
		if _motion:
			_x[i] += _vx[i] * delta
			_y[i] += _vy[i] * delta
		# Everything slows; smoke and embers also rise.
		_vx[i] *= 0.94
		_vy[i] = _vy[i] * 0.94 + (18.0 * delta if _span[i] > 1.0 else 0.0)


func _draw() -> void:
	for i in _left.size():
		if _left[i] <= 0.0:
			continue
		if is_instance_valid(_warm) and _tint[i].is_equal_approx(PaletteData.COLOURS[&"flame_hot"]):
			continue
		# **Fading is alpha, not a smaller palette.** The colour stays what it
		# was drawn as, so a spark is `flame_hot` for as long as it is
		# anything at all - which is what keeps it exempt from the night ramp
		# right to the end.
		var lit: Color = _tint[i]
		lit.a = clampf(_left[i] / maxf(_span[i], 0.01), 0.0, 1.0)
		# A drop is water until it lands: whole for most of its flight.
		if _falling[i] == 2:
			lit.a = minf(lit.a * 3.0, 1.0)
		var wide := float(_size[i])
		draw_rect(Rect2(floorf(_x[i]), floorf(_y[i]), wide, wide), lit, true)


## Hot procedural cores share the authored forms' semantic emission layer.
func _draw_sparks() -> void:
	for i in _left.size():
		if _left[i]<=0.0 or not _tint[i].is_equal_approx(PaletteData.COLOURS[&"flame_hot"]):
			continue
		var lit: Color = _tint[i]
		lit.a = clampf(_left[i]/maxf(_span[i],0.01),0.0,1.0)
		var wide := float(_size[i])
		_warm.draw_rect(Rect2(floorf(_x[i]),floorf(_y[i]),wide,wide),lit,true)


# ------------------------------------------------------------------ noticing

## Look at what changed since last frame, and make something of it.
func _watch(delta: float) -> void:
	var tile := float(GameData.TILE_SIZE)
	var per := tile / float(Player.SUBTILE)

	# **Deaths, impacts and what is on fire.**
	var entities: Dictionary = {}
	for id in Entities.ids(_state):
		var one := Entities.get_one(_state, int(id))
		if one.is_empty():
			continue
		var at := Vector2(float(one["pos"][0]), float(one["pos"][1])) * per
		var hurt := int(one.get("hurt", 0))
		entities[int(id)] = [at, hurt]
		var was: Variant = _seen_entities.get(int(id), null)
		if was == null:
			continue
		# **On the hit, not for as long as it shows.** `hurt` is a countdown
		# that stays set for several ticks, so emitting while it is above zero
		# emitted every frame of it - seventy-five zombies being shot became
		# two hundred particles a frame. The spark belongs to the moment the
		# counter goes up.
		if hurt > int((was as Array)[1]):
			_burst(at, 2, &"spark", SPARK, 40.0)
			# **Restrained, as section 18 asks.** One pixel, sometimes, and
			# never a spray: this is a cozy game whose other half is zombies,
			# not a game about blood.
			if randf() < 0.25:
				_burst(at, 1, &"blood", BLOOD, 22.0)
		if Combat.is_burning(_state, int(id)) and randf() < 0.25:
			_burst(at, 1, &"ember", EMBER, 16.0)
	# **The guns keep their own pass**, because a muzzle flash is a moment
	# and a moment missed is a moment gone. It is cheap: only things that can
	# shoot are asked, and there are never many of those.
	# Muzzles are observed once per fixed tick by PixelEffects, rather than
	# re-emitting for every rendered frame of the reload flash.

	for id in _seen_entities:
		if entities.has(id):
			continue
		# It was here and it is not. Dust, and a little blood.
		var where: Vector2 = (_seen_entities[id] as Array)[0]
		_burst(where, 5, &"dust", DUST, 34.0)
		_burst(where, 1, &"blood", BLOOD, 26.0)
	_seen_entities = entities

	# **Guns, chimneys and wreckage, and not every frame.**
	#
	# Walking the whole farm sixty times a second to find out whether a
	# chimney should smoke is two hundred and fifty occupants of dictionary
	# work for an event that happens three times a second. The scan runs on
	# the same clock the smoke does.
	#
	# The keys are **not sorted**, and that is deliberate rather than an
	# oversight: sorting is how `src/core/` keeps two runs identical, and
	# nothing here is in a run. Order between two puffs of smoke is not a
	# fact anybody can observe.
	_smoke_due -= delta
	if _smoke_due > 0.0:
		return
	_smoke_due = 0.35
	# At most three localized flames per smoke beat, rotating through live
	# burning actors. Large groups keep their cheap one-pixel embers.
	var burning: Array[int] = []
	for id in Entities.ids(_state):
		if Combat.is_burning(_state,int(id)):
			burning.append(int(id))
	for i in mini(3,burning.size()):
		var id := burning[(_burn_cursor+i)%burning.size()]
		var one := Entities.get_one(_state,id)
		var at := Vector2(one["pos"][0],one["pos"][1])*per
		_forms.emit(&"flame",at-Vector2(0,4))
	if not burning.is_empty():
		_burn_cursor = (_burn_cursor+3)%burning.size()
	var occupants: Dictionary = _state["occupants"]
	var standing: Dictionary = {}
	var chimneys: Dictionary = {}
	for idx in occupants:
		var on: Dictionary = occupants[idx]
		var id: StringName = on["id"]
		standing[int(idx)] = id
		var at := (Vector2(Grid.cell(int(idx))) + Vector2(0.5, 0.4)) * tile
		if id in [&"kitchen", &"workshop", &"generator", &"house"]:
			if id != &"house" and not WorldView.station_running(_state, id, Building.anchor_of(_state, Grid.cell(int(idx)))):
				continue
			var anchor: Array = on.get("anchor", [Grid.cell(int(idx)).x, Grid.cell(int(idx)).y])
			if id == &"house":
				var corner := Farm.house_bounds(_state).position
				anchor = [corner.x, corner.y]
			var name := "%s@%s" % [id, str(anchor)]
			if chimneys.has(name):
				continue
			chimneys[name] = true
			at = ArtPlacement.emission(id, Vector2(anchor[0], anchor[1]) * tile, &"smoke", at,
				Building.bounds_at(_state, Vector2i(anchor[0], anchor[1])).size)
			_burst(at, 1, &"smoke", SMOKE, 8.0)
			_forms.emit(&"smoke",at,Vector2(0,-4))
		elif _is_wrecked(on):
			_burst(at, 1, &"smoke", SMOKE, 10.0)
			_forms.emit(&"smoke",at,Vector2(0,-4))
	for idx in _seen_occupants:
		if standing.has(idx):
			continue
		# Something the player built has come down.
		var where := (Vector2(Grid.cell(int(idx))) + Vector2(0.5, 0.5)) * tile
		_burst(where, 7, &"dust", DUST, 40.0)
		_burst(where, 3, &"smoke", SMOKE, 14.0)
		_forms.emit(&"dust",where)
	_seen_occupants = standing


## The cells with something that shoots on them, remembered.
##
## Rebuilt when occupancy changes, including same-count replacements. Never
## rescans the whole farm just because another rendered frame has elapsed.
var _guns: Array = []
var _guns_for := -1


func _gun_cells() -> Array:
	var occupants: Dictionary = _state["occupants"]
	var version := int(_state.get("grid_version", 0))
	if version == _guns_for:
		return _guns
	_guns_for = version
	_guns = []
	for idx in occupants:
		var entry: Variant = Building.entry_of(
			StringName((occupants[idx] as Dictionary)["id"]))
		if entry != null and (entry as Dictionary).has("reload_ticks"):
			_guns.append(int(idx))
	return _guns


## Whether this tower fired in the last moment. The same question `WorldView`
## and `Lighting` ask, so the flash, the light and the sparks are one event.
func _firing(on: Dictionary) -> bool:
	return WorldView.just_fired(on)


## Whether it is battered enough to be smoking. The same threshold the art and
## the tint use, so all three agree about when something looks finished.
func _is_wrecked(on: Dictionary) -> bool:
	var full := WorldView.levelled_stat(on, "hp")
	if full <= 0:
		return false
	return float(int(on.get("hp", full))) / float(full) < 0.4


# ------------------------------------------------------------------ emitting

## `how_many` of a kind, thrown out from a point.
##
## **The oldest is reused when the pool is full.** Not "refuse to emit": a
## busy wave would then show the first hundred sparks of the night and
## nothing afterwards, which is worse than showing the most recent hundred.
func _burst(at: Vector2, how_many: int, kind: StringName, colour: String,
		speed: float) -> void:
	var wanted := int(ceilf(float(how_many) * _density))
	if wanted <= 0 or _cap <= 0:
		return
	var span := float(LIFE.get(kind, 0.4))
	var tint: Color = PaletteData.COLOURS[StringName(colour)]
	for _one in wanted:
		var i := _slot()
		if i < 0:
			return
		var angle := randf() * TAU
		var thrown := speed * (0.4 + randf() * 0.8)
		_x[i] = at.x
		_y[i] = at.y
		_vx[i] = cos(angle) * thrown
		_vy[i] = sin(angle) * thrown - (10.0 if kind == &"smoke" else 0.0)
		_left[i] = span * (0.7 + randf() * 0.6)
		_span[i] = _left[i]
		_size[i] = 2 if kind == &"dust" or kind == &"smoke" else 1
		_tint[i] = tint
		_falling[i] = 0


# ------------------------------------------------------------------ the snow

## Whether it is snowing on screen (task 0159): winter on the farm
## (`SeasonView.season_on_screen`), with particles allowed and moving.
func snowing() -> bool:
	return not _state.is_empty() and _density > 0.0 and _motion and _cap > 0 		and SeasonView.season_on_screen(_state) == SeasonView.WINTER


## How many flakes are in the air - for `input_v1`.
func flakes() -> int:
	var n := 0
	for i in _left.size():
		if _left[i] > 0.0 and _falling[i] == 1:
			n += 1
	return n


## Let flakes into the camera's view from its top edge - and, the first
## frame it snows, all the way down it, so winter does not open on an empty
## sky. On the wall clock, like every particle.
func _snow(delta: float) -> void:
	var now := snowing()
	if not now:
		_snow_was = false
		_snow_due = 0.0
		return
	var to_world := get_global_transform_with_canvas().affine_inverse()
	var corner := to_world * Vector2.ZERO
	var view := to_world.basis_xform(get_viewport_rect().size)
	var crossing := view.y / SNOW_FALL.y
	if not _snow_was:
		_snow_was = true
		for _i in int(SNOW_PER_SECOND * _density * crossing):
			_flake(corner, view, randf() * view.y)
	_snow_due += SNOW_PER_SECOND * _density * delta
	while _snow_due >= 1.0:
		_snow_due -= 1.0
		_flake(corner, view, -2.0)


func _flake(corner: Vector2, view: Vector2, down: float) -> void:
	var i := _slot()
	if i < 0:
		return
	_x[i] = corner.x + randf() * view.x
	_y[i] = corner.y + down
	_vx[i] = (randf() * 2.0 - 1.0) * SNOW_FALL.x
	_vy[i] = SNOW_FALL.y * (0.75 + randf() * 0.5)
	_left[i] = maxf((view.y + 4.0 - down) / _vy[i], 0.1)
	_span[i] = 0.6
	_size[i] = 1
	_tint[i] = PaletteData.COLOURS[SNOW_COLOURS[randi() % SNOW_COLOURS.size()]]
	_falling[i] = 1


# ----------------------------------------------------------------- the spray

## Whether the sprinklers are running on screen (task 0178): the first hour
## of the day, with particles allowed and moving.
func spraying() -> bool:
	return not _state.is_empty() and _density > 0.0 and _motion and _cap > 0 \
		and int(_state["phase"]) == Phases.DAY \
		and int(_state["day_tick"]) < Phases.tick_at_minute(SPRAY_UNTIL_MINUTE)


## How many drops are in the air - for `input_v1`.
func drops() -> int:
	var n := 0
	for i in _left.size():
		if _left[i] > 0.0 and _falling[i] == 2:
			n += 1
	return n


## Water from every sprinkler the camera can see, thrown out over the cells it
## waters: along the four ways for a cross, all round for a square, and further
## the further it reaches. On the wall clock, like every particle.
func _spray(delta: float) -> void:
	if not spraying():
		_spray_due.clear()
		return
	var to_world := get_global_transform_with_canvas().affine_inverse()
	var view := Rect2(to_world * Vector2.ZERO, to_world.basis_xform(get_viewport_rect().size)).grow(32.0)
	var tile := float(GameData.TILE_SIZE)
	var occupants: Dictionary = _state["occupants"]
	# Cell indices, so these are integers and sort as integers.
	var keys: Array = occupants.keys()
	keys.sort()
	for idx in keys:
		var id := StringName((occupants[idx] as Dictionary)["id"])
		if not Building.sprays(id):
			continue
		var head := (Vector2(Grid.cell(int(idx))) + Vector2(0.5, 0.5)) * tile
		if not view.has_point(head):
			continue
		var entry: Dictionary = GameData.BUILDINGS[id]
		var reach := float(int(entry["spray_reach"]))
		var cross := StringName(entry["spray"]) == &"cross"
		# **Already in the air** the first frame a sprinkler is seen running,
		# as the snow is: a morning does not open on a dry nozzle.
		if not _spray_due.has(int(idx)):
			for _i in int(SPRAY_PER_SECOND * _density * reach * SPRAY_LIFE):
				_drop(head, reach * tile, cross, randf())
		var due := float(_spray_due.get(int(idx), 0.0)) + SPRAY_PER_SECOND * _density * delta * reach
		while due >= 1.0:
			due -= 1.0
			_drop(head, reach * tile, cross)
		_spray_due[int(idx)] = due


## One drop from `head` toward a point up to `out` away, `progress` of the way
## through its flight already.
func _drop(head: Vector2, out: float, cross: bool, progress: float = 0.0) -> void:
	var i := _slot()
	if i < 0:
		return
	var angle := float(randi() % 4) * PI / 2.0 + (randf() - 0.5) * 0.4 if cross else randf() * TAU
	var landing := out * (0.35 + randf() * 0.75)
	var flight := SPRAY_LIFE * (0.8 + randf() * 0.4)
	_vx[i] = cos(angle) * landing / SPRAY_LIFE
	_vy[i] = sin(angle) * landing / SPRAY_LIFE
	_x[i] = head.x + _vx[i] * flight * progress
	_y[i] = head.y - 3.0 + _vy[i] * flight * progress
	_left[i] = flight * (1.0 - progress)
	_span[i] = flight
	_size[i] = 1
	_tint[i] = PaletteData.COLOURS[SPRAY_COLOURS[randi() % SPRAY_COLOURS.size()]]
	_falling[i] = 2


## The next slot in the ring.
##
## **Constant time, and it has to be.** The first version scanned the pool for
## a free slot and, failing that, scanned it again for the oldest - four
## hundred and twenty steps per particle. On a busy night that is two hundred
## particles a frame times two scans, and it measured at **41 milliseconds a
## frame** against a budget of sixteen. A ring overwrites in emission order,
## which is age order, so it gets the same answer by not asking the question.
func _slot() -> int:
	if _left.is_empty():
		return -1
	var i := _next
	_next = (_next + 1) % _left.size()
	return i
