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
## ## Drawn in the world, unlike task 0076's lights
##
## The lights had to go *over* the night ramp, because a glow is mostly halo
## and a halo is dim by nature - the ramp tinted it blue and there was no
## brightness to exempt. A particle is the opposite: one or two pixels, and
## the bright ones are drawn in `flame_hot` and `flame`, which are above task
## 0071's `NIGHT_WARM_KEEP`. So a spark exempts itself and stays orange while
## smoke, drawn in `stone_dark`, goes blue with the rest of the farm - which
## is what smoke at night should do.
##
## Same rule, opposite answer, for a reason that is about the art and not
## about the code.
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

## The cap when nothing says otherwise. `video/max_particles` moves it and
## `a11y/particle_density` scales what is asked for - one turns the ceiling
## down and the other turns the tap down, which are different things.
const DEFAULT_CAP := 420

var _state: Dictionary = {}
var _cap := DEFAULT_CAP
var _density := 1.0

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
var _next := 0

# What the farm looked like last frame, so this frame can see what changed.
var _seen_entities: Dictionary = {}
var _seen_occupants: Dictionary = {}
var _smoke_due := 0.0


func _ready() -> void:
	z_index = 15                # over the farm, under task 0076's lights
	z_as_relative = false
	_resize(DEFAULT_CAP)
	_read_settings()


func show_state(state: Dictionary) -> void:
	_state = state


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
	if cap != null:
		_resize(maxi(int(cap), 0))
	var density: Variant = service.get_value(&"a11y/particle_density")
	if density != null:
		_density = clampf(float(density), 0.0, 1.0)


func cap() -> int:
	return _cap


func density() -> float:
	return _density


## For `input_check`, which has to turn these off and prove the night is the
## same without them.
func set_density(value: float) -> void:
	_density = clampf(value, 0.0, 1.0)


func set_cap(value: int) -> void:
	_resize(maxi(value, 0))


## How many are alive right now. The assert that the cap is a cap.
func live() -> int:
	var n := 0
	for i in _left.size():
		if _left[i] > 0.0:
			n += 1
	return n


func _resize(size: int) -> void:
	_cap = size
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
	for i in size:
		_left[i] = 0.0
	_next = 0


func _process(delta: float) -> void:
	if _state.is_empty():
		return
	_advance(delta)
	if _density > 0.0 and _cap > 0:
		_watch(delta)
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
		_x[i] += _vx[i] * delta
		_y[i] += _vy[i] * delta
		# Everything slows; smoke and embers also rise.
		_vx[i] *= 0.94
		_vy[i] = _vy[i] * 0.94 + (18.0 * delta if _span[i] > 1.0 else 0.0)


func _draw() -> void:
	for i in _left.size():
		if _left[i] <= 0.0:
			continue
		# **Fading is alpha, not a smaller palette.** The colour stays what it
		# was drawn as, so a spark is `flame_hot` for as long as it is
		# anything at all - which is what keeps it exempt from the night ramp
		# right to the end.
		var lit: Color = _tint[i]
		lit.a = clampf(_left[i] / maxf(_span[i], 0.01), 0.0, 1.0)
		var wide := float(_size[i])
		draw_rect(Rect2(floorf(_x[i]), floorf(_y[i]), wide, wide), lit, true)


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
	for idx in _gun_cells():
		var on: Variant = (_state["occupants"] as Dictionary).get(int(idx),
			null)
		if on != null and _firing(on as Dictionary):
			var muzzle := (Vector2(Grid.cell(int(idx)))
				+ Vector2(0.8, -0.2)) * tile
			_burst(muzzle, 3, &"spark", SPARK, 55.0)

	for id in _seen_entities:
		if entities.has(id):
			continue
		# It was here and it is not. Dust, and a little blood.
		var where: Vector2 = (_seen_entities[id] as Array)[0]
		_burst(where, 5, &"dust", DUST, 34.0)
		_burst(where, 2, &"blood", BLOOD, 26.0)
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
	var occupants: Dictionary = _state["occupants"]
	var standing: Dictionary = {}
	for idx in occupants:
		var on: Dictionary = occupants[idx]
		var id: StringName = on["id"]
		standing[int(idx)] = id
		var at := (Vector2(Grid.cell(int(idx))) + Vector2(0.5, 0.4)) * tile
		if id == &"kitchen" or id == &"workshop" or id == &"house":
			_burst(at, 1, &"smoke", SMOKE, 8.0)
		elif _is_wrecked(on):
			_burst(at, 1, &"smoke", SMOKE, 10.0)
	for idx in _seen_occupants:
		if standing.has(idx):
			continue
		# Something the player built has come down.
		var where := (Vector2(Grid.cell(int(idx))) + Vector2(0.5, 0.5)) * tile
		_burst(where, 7, &"dust", DUST, 40.0)
		_burst(where, 3, &"smoke", SMOKE, 14.0)
	_seen_occupants = standing


## The cells with something that shoots on them, remembered.
##
## Rebuilt when the number of things on the farm changes, which is when a
## player builds or something falls over - not sixty times a second. The same
## trick `Power` uses for its generator list, and for the same reason.
var _guns: Array = []
var _guns_for := -1


func _gun_cells() -> Array:
	var occupants: Dictionary = _state["occupants"]
	if occupants.size() == _guns_for:
		return _guns
	_guns_for = occupants.size()
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
	var left := int(on.get("reload", 0))
	if left <= 0:
		return false
	var entry: Variant = Building.entry_of(StringName(on["id"]))
	if entry == null:
		return false
	var whole := int((entry as Dictionary).get("reload_ticks", 0))
	return whole > 0 and left * 100 >= whole * WorldView.FLASH_PERCENT


## Whether it is battered enough to be smoking. The same threshold the art and
## the tint use, so all three agree about when something looks finished.
func _is_wrecked(on: Dictionary) -> bool:
	var entry: Variant = Building.entry_of(StringName(on["id"]))
	if entry == null:
		return false
	var full := int((entry as Dictionary).get("hp", 0))
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


## The next slot in the ring.
##
## **Constant time, and it has to be.** The first version scanned the pool for
## a free slot and, failing that, scanned it again for the oldest - four
## hundred and twenty steps per particle. On a busy night that is two hundred
## particles a frame times two scans, and it measured at **41 milliseconds a
## frame** against a budget of sixteen. A ring overwrites in emission order,
## which is age order, so it gets the same answer by not asking the question.
func _slot() -> int:
	if _cap <= 0:
		return -1
	var i := _next
	_next = (_next + 1) % _cap
	return i
