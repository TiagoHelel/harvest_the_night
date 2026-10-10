class_name Save
extends RefCounted

## Quitting on day 4 and coming back to day 4.
##
## Two files, because they answer two questions. The **run** is the game in
## progress: it is the core state and nothing else, so saving is serialisation
## rather than a second description of the world that could disagree with the
## first. The **profile** is what outlives a run: unlocks, statistics, the best
## night reached.
##
## Static functions rather than an autoload. Nothing here needs to be in the
## tree, and a `--script` check can call it directly.
##
## ## The format
##
##     "HTNS"          magic, so a file that is not ours is refused on sight
##     u32 version     of the format, not of the game
##     u32 length      of the payload
##     u32 checksum    of the payload
##     bytes           var_to_bytes(payload)
##
## `var_to_bytes` rather than JSON because it is exact: `StringName`,
## `PackedByteArray`, integer dictionary keys and the int-versus-float
## distinction all survive, and the determinism guard would notice immediately
## if any of them did not. **Never `var_to_bytes_with_objects`** - that would
## let a save file instantiate a script, and a save file is data somebody else
## can hand you.
##
## The checksum is not decoration. `bytes_to_var` on a truncated file returns
## null and prints two engine errors on the way; checking the length and the
## checksum first means a damaged save is refused cleanly, with a message about
## the save rather than about Variant decoding.

const MAGIC := "HTNS"
const FORMAT_VERSION := 1

const RUN_PATH := "user://run.sav"
const PROFILE_PATH := "user://profile.sav"

const _FNV_OFFSET := 2166136261
const _FNV_PRIME := 16777619
const _MASK := 0xFFFFFFFF

## Why the last read of a run did not produce one, as a string key, or `&""`.
##
## **A file that will not load is not the same as no file at all**, and the
## title screen has to be able to tell them apart: one of them means CONTINUE
## is absent because there is nothing to continue, and the other means
## somebody's run is sitting on the disk unreadable and they deserve to be
## told rather than quietly given a new farm.
static var _trouble: StringName = &""

## And what the trouble was about, for the log and for a check.
static var _trouble_detail := ""

## The trouble a save can be in. Each is a string key with a line behind it.
const NO_SAVE := &""
const TOO_SHORT := &"SAVE_TOO_SHORT"
const NOT_OURS := &"SAVE_NOT_OURS"
const TRUNCATED := &"SAVE_TRUNCATED"
const DAMAGED := &"SAVE_DAMAGED"
const FROM_THE_FUTURE := &"SAVE_FROM_THE_FUTURE"
const NO_MIGRATION := &"SAVE_NO_MIGRATION"
const NOT_A_SAVE := &"SAVE_NOT_A_SAVE"


## What a player who has never finished anything has.
##
## Tasks 0062 and 0069 fill this out; the shape is here so the first migration
## has somewhere obvious to go.
static func default_profile() -> Dictionary:
	return {
		"version": FORMAT_VERSION,
		"runs_started": 0,
		"runs_won": 0,
		"best_night": 0,
		"unlocks": [],
		"stats": {},
		# **The tips shown** (task 0195), by id: once ever, so a tip a
		# player has seen in one run does not teach them again in the next.
		"tips_seen": [],
	}


# ---------------------------------------------------------------------- run

static func has_run() -> bool:
	return FileAccess.file_exists(RUN_PATH)


## Write the game in progress. The state is already plain data, so this is the
## whole of it plus a wrapper.
static func write_run(state: Dictionary) -> bool:
	return write_run_at(RUN_PATH, state)


## The same, somewhere else. `tools/goldens/` is the only other caller: a
## golden save has to be a real one, written by the real writer, or it tests
## the check and not the game.
static func write_run_at(path: String, state: Dictionary) -> bool:
	return _write(path, {"state": state})


## Read the game in progress, or an empty Dictionary when there is not one, or
## when the file is damaged. **Never crashes and never half-loads**: a bad file
## leaves the caller with nothing, which it can tell from a good one.
static func read_run() -> Dictionary:
	return read_run_at(RUN_PATH)


## Read a run from somewhere else, through every step the real one takes -
## the header, the checksum, the migrations and the reconcile. The golden
## saves are loaded with this, so what is checked is the road a player's save
## travels and not a shorter one built for the check.
static func read_run_at(path: String) -> Dictionary:
	var payload := _read(path)
	if payload.is_empty():
		return {}
	var state: Dictionary = payload.get("state", {})
	if state.is_empty() or not state.has("tick"):
		return _no(NOT_A_SAVE, "%s parsed but holds no game" % path)

	# **The numbered migrations first, then the shape.** A migration is
	# written against the shape of the version it starts from, so a
	# reconcile that ran before it would hand it a state with this build's
	# keys in and the migration would be reading the wrong thing.
	var was := int(state.get("version", 1))
	if was > State.VERSION:
		return _no(FROM_THE_FUTURE,
			"the run is state %d and this build knows %d"
				% [was, State.VERSION])
	if was < State.VERSION:
		var brought := step_up(state, was, State.VERSION, migrations())
		if brought.is_empty():
			return _no(NO_MIGRATION,
				"nothing brings a state %d run up to %d"
					% [was, State.VERSION])
		state = brought

	# **And then the shape, every time, not only when the version moved.**
	# Most of what changes about a save never bumps a version: a subsystem
	# arrives, a resource is added, a field appears on a structure. Those are
	# not a migration, they are a new game having a key this one does not.
	for note in State.reconcile(state):
		push_warning("Save: %s" % note)
	state["version"] = State.VERSION
	return state


## Whether there is a run worth offering to continue.
##
## Not `has_run()`, which only says a file exists. A save that cannot be read
## must not put CONTINUE on the title screen: a button that throws away the
## run it offered to resume is worse than no button.
static func can_continue() -> bool:
	return not read_run().is_empty()


## Why the last read failed, as a string key, or `&""` when it did not fail
## or there was nothing to read.
static func trouble() -> StringName:
	return _trouble


## The same thing in a sentence, for the log.
static func trouble_detail() -> String:
	return _trouble_detail


## Refuse, remember why, and say it once. **The file is never removed**: a
## save this build cannot read is a save a later build may well be able to,
## and deleting somebody's run because we did not understand it is the one
## thing this module must not do.
static func _no(which: StringName, why: String) -> Dictionary:
	_trouble = which
	_trouble_detail = why
	push_warning("Save: %s" % why)
	return {}


static func delete_run() -> void:
	_remove(RUN_PATH)
	_remove(RUN_PATH + ".bak")


# ------------------------------------------------------------------ profile

static func write_profile(profile: Dictionary) -> bool:
	return _write(PROFILE_PATH, {"profile": profile})


## The profile, or a fresh one. A missing profile is the first launch, not an
## error; a damaged one costs the player their statistics and nothing else, so
## it falls back rather than refusing to start the game.
static func read_profile() -> Dictionary:
	var payload := _read(PROFILE_PATH)
	if payload.is_empty():
		return default_profile()
	var profile: Dictionary = payload.get("profile", {})
	if profile.is_empty():
		return default_profile()
	# A profile from a newer build keeps what this build understands rather
	# than being thrown away: losing somebody's statistics because they opened
	# an older copy of the game would be unforgivable.
	var base := default_profile()
	base.merge(profile, true)
	base["version"] = FORMAT_VERSION
	return base


# ------------------------------------------------------------ the file itself

static func _write(path: String, payload: Dictionary) -> bool:
	var body := var_to_bytes(payload)

	var out := PackedByteArray()
	out.append_array(MAGIC.to_ascii_buffer())
	_append_u32(out, FORMAT_VERSION)
	_append_u32(out, body.size())
	_append_u32(out, checksum(body))
	out.append_array(body)

	var temp := path + ".tmp"
	var f := FileAccess.open(temp, FileAccess.WRITE)
	if f == null:
		push_error("Save: cannot write %s (error %d)"
			% [temp, FileAccess.get_open_error()])
		return false
	f.store_buffer(out)
	f.close()

	# The previous save becomes the backup, and only then does the new one take
	# its place. A crash at any point leaves either the old file, or the old
	# file as .bak plus a complete .tmp - never a half-written save.
	if FileAccess.file_exists(path):
		_remove(path + ".bak")
		_rename(path, path + ".bak")
	return _rename(temp, path)


## Read and check a file. An empty Dictionary means "no usable save", for every
## reason: missing, too short, wrong magic, wrong length, bad checksum, or a
## payload that will not decode.
static func _read(path: String) -> Dictionary:
	_trouble = NO_SAVE
	_trouble_detail = ""
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("Save: cannot read %s (error %d)"
			% [path, FileAccess.get_open_error()])
		return {}
	var raw := f.get_buffer(f.get_length())
	f.close()

	const HEADER := 16
	if raw.size() < HEADER:
		return _no(TOO_SHORT, "%s is %d bytes, too short to be a save"
			% [path, raw.size()])
	if raw.slice(0, 4).get_string_from_ascii() != MAGIC:
		return _no(NOT_OURS, "%s is not a %s save file" % [path, MAGIC])

	var version := _read_u32(raw, 4)
	var length := _read_u32(raw, 8)
	var sum := _read_u32(raw, 12)
	var body := raw.slice(HEADER)

	if body.size() != length:
		return _no(TRUNCATED,
			"%s claims %d bytes of payload and has %d - it was truncated"
				% [path, length, body.size()])
	if checksum(body) != sum:
		return _no(DAMAGED,
			"%s is damaged - the checksum does not match" % path)

	if version > FORMAT_VERSION:
		return _no(FROM_THE_FUTURE,
			"%s is format %d and this build understands %d"
				% [path, version, FORMAT_VERSION])

	var payload: Variant = bytes_to_var(body)
	if typeof(payload) != TYPE_DICTIONARY:
		return _no(NOT_A_SAVE, "%s decoded to a %s, not a save"
			% [path, type_string(typeof(payload))])

	if version < FORMAT_VERSION:
		payload = _migrate(payload, version)
		if (payload as Dictionary).is_empty():
			return _no(NO_MIGRATION,
				"nothing brings a format %d file up to %d"
					% [version, FORMAT_VERSION])
	return payload


## Bring an older **file** forward. The envelope, not what is inside it.
##
## Nothing to do yet - there has only ever been format 1, because the header
## and the encoding have not changed. What changes is the state, and that
## goes through `migrations()` and `State.reconcile()` in `read_run()`.
static func _migrate(payload: Dictionary, from_version: int) -> Dictionary:
	return step_up(payload, from_version, FORMAT_VERSION, file_migrations())


## One `Callable` per version bump, keyed by the version it starts from.
##
## `migrations()[3]` takes a state written by a build whose `State.VERSION`
## was 3 and returns one a build with version 4 understands. It does not have
## to fill in new keys - `State.reconcile()` does that for every load - only
## the things filling in cannot express.
##
## Every bump so far has widened the farm, and always to the right and down:
## 40x18 at version 1, 45x20 at 2, 45x25 with larger buildings at 3, and at 4
## Stardew Valley's Standard Farm, 80x65. A cell keeps its coordinates through
## all of them - only its index changes - so crops, buildings, jobs and live
## entities stay exactly where they were, and the new ground is today's map.
##
## Version 5 (task 0151) changed what a number means instead:
## `_night_is_the_date_v4`.
static func migrations() -> Dictionary:
	return {1: _expand_farm_v1, 2: _expand_farm_v2, 3: _expand_farm_v3,
		4: _night_is_the_date_v4, 5: _farm_v1_0_from_v5, 6: _crops_by_days_v6,
		7: _fish_by_species_v7, 8: _shipping_bin_v8}


## The farm each version was written with.
const V1_FARM := Vector2i(40, 18)
const V2_FARM := Vector2i(45, 20)
const V3_FARM := Vector2i(45, 25)


static func _widened_index(index: int, width: int) -> int:
	return index if index < 0 else (index / width) * Grid.WIDTH + index % width


static func _widened_table(table: Dictionary, width: int) -> Dictionary:
	var result: Dictionary = {}
	var keys := table.keys()
	keys.sort()
	for key in keys:
		result[_widened_index(int(key), width)] = table[key]
	return result


## Whether a save's farm is already the size this build plays on.
static func _is_today(state: Dictionary) -> bool:
	return (state.get("terrain", PackedByteArray()) as PackedByteArray).size() == Grid.CELLS


## Lay a farm `size` cells across onto today's grid, every cell at the same
## coordinates. The ground it never had comes from a new game, with the trees
## and stones standing on it; every cache keyed by a cell index is thrown away
## to be rebuilt. Empty when the farm is not that size.
##
## **Today's ground, not today's farmstead.** A save keeps its own house,
## stall, workshop, well, animals and beds where it built them; today's stand
## in the middle of the farm, and laying them in too would give it two of
## each. Their floors and beds go back to grass.
static func _widen(previous: Dictionary, size: Vector2i) -> Dictionary:
	var state := previous.duplicate(true)
	var terrain: PackedByteArray = state.get("terrain", PackedByteArray())
	if terrain.size() != size.x * size.y:
		return {}
	var farm := Farm.initial()
	var widened: PackedByteArray = farm["terrain"]
	var standing: Dictionary = farm["occupants"]
	for idx in widened.size():
		var built := standing.has(idx) and not GameData.GATHERING.has(StringName(standing[idx]["id"]))
		if int(widened[idx]) == Farm.Terrain.SOIL or (built and int(widened[idx]) == Farm.Terrain.FLOOR):
			widened[idx] = Farm.Terrain.GRASS
	for old_index in terrain.size():
		widened[_widened_index(old_index, size.x)] = terrain[old_index]
	state["terrain"] = widened
	for key in ["occupants", "rubble", "plots", "crafting", "livestock", "repair_debt", "produced"]:
		if state.has(key):
			state[key] = _widened_table(state[key], size.x)
	var occupants: Dictionary = state.get("occupants", {})
	var fresh: Array = standing.keys()
	fresh.sort()
	for idx in fresh:
		var cell := Grid.cell(int(idx))
		if (cell.x >= size.x or cell.y >= size.y) 				and GameData.GATHERING.has(StringName(standing[idx]["id"])):
			occupants[idx] = standing[idx]
	state["occupants"] = occupants
	for entry in state.get("regrowing", []):
		entry[Gathering.PENDING_CELL] = _widened_index(int(entry[Gathering.PENDING_CELL]), size.x)
	if state.has("expiring"):
		var expiring: Array = []
		for idx in state["expiring"]:
			expiring.append(_widened_index(int(idx), size.x))
		state["expiring"] = expiring
	for entity in state.get("entities", {}).values():
		for key in ["chewing", "winding_at"]:
			if entity.has(key):
				entity[key] = _widened_index(int(entity[key]), size.x)
	if state.has("power"):
		var power: Dictionary = state["power"]
		power["burning"] = _widened_table(power.get("burning", {}), size.x)
		power["plants"] = []
		power["for_version"] = -1
	for key in Pathing.initial():
		state[key] = Pathing.initial()[key]
	for key in ["tower", "livestock"]:
		state[key + "_cells"] = []
		state[key + "_version"] = -1
	state["grid_version"] = int(state.get("grid_version", 0)) + 1
	return state


## Version 2 widened the first 40x18 farm. Nothing moves and no harvested
## tree comes back.
static func _expand_farm_v1(previous: Dictionary) -> Dictionary:
	var state := previous.duplicate(true) if _is_today(previous) else _widen(previous, V1_FARM)
	if state.is_empty():
		return {}
	state["version"] = 2
	return state


## Version 3 added five clear southern rows and larger structure footprints.
## Never cover a saved plot or another occupant to make a building larger.
static func _expand_farm_v2(previous: Dictionary) -> Dictionary:
	var state := previous.duplicate(true) if _is_today(previous) else _widen(previous, V2_FARM)
	if state.is_empty():
		return {}
	var before_porch := House.porch(state)
	var groups := {}
	var occupants: Dictionary = state["occupants"]
	var old_keys := occupants.keys()
	old_keys.sort()
	for idx in old_keys:
		var on: Dictionary = occupants[idx]
		var id: StringName = on.get("id", &"")
		if Building.size_of(id) == Vector2i.ONE:
			continue
		var key := "%s@%s" % [id, str(on.get("anchor", []))]
		if not groups.has(key):
			groups[key] = []
		groups[key].append(Grid.cell(int(idx)))
	for key in GameData.sorted_names(groups.keys()):
		var old_parts: Array = groups[key]
		var old_origin: Vector2i = old_parts[0]
		var prototype: Dictionary = Farm.occupant(state, old_origin).duplicate(true)
		var id: StringName = prototype["id"]
		var origin := old_origin + Vector2i(-2, 1) if id == &"house" and old_parts.size() == 9 else old_origin
		var wanted := Building.size_of(id)
		if not _room_to_expand(state, origin, wanted, old_parts):
			if id != &"house":
				continue # A dense legacy station keeps its saved cells and jobs.
			origin = Vector2i(-1, -1)
			for y in range(20, Grid.HEIGHT - wanted.y):
				for x in range(1, Grid.WIDTH - wanted.x):
					if _room_to_expand(state, Vector2i(x, y), wanted, old_parts):
						origin = Vector2i(x, y)
						break
				if origin.x >= 0:
					break
			if origin.x < 0:
				return {}
		if id == &"house":
			for cell in old_parts:
				occupants.erase(Grid.index(cell))
			prototype["anchor"] = [origin.x, origin.y]
		for cell in Building.footprint(id, origin):
			if not occupants.has(Grid.index(cell)):
				occupants[Grid.index(cell)] = prototype.duplicate(true)
	if not Farm.house_bounds(state).size == Vector2i.ZERO:
		state["house_cell"] = Farm._centre_of(occupants)
	var here := Player.cell(state)
	if here == before_porch or not Farm.walkable(state, here):
		var porch := House.porch(state)
		state["player"]["pos"] = [porch.x * Player.SUBTILE + Player.SUBTILE / 2,
			porch.y * Player.SUBTILE + Player.SUBTILE / 2]
	for key in Pathing.initial():
		state[key] = Pathing.initial()[key]
	state["grid_version"] = int(state.get("grid_version", 0)) + 1
	state["version"] = 3
	return state


## Version 4 is Stardew Valley's Standard Farm, 80x65, with the 45x25 farm of
## version 3 its top left corner, character for character.
static func _expand_farm_v3(previous: Dictionary) -> Dictionary:
	var state := previous.duplicate(true) if _is_today(previous) else _widen(previous, V3_FARM)
	if state.is_empty():
		return {}
	state["version"] = 4
	return state


## **4 to 5: the night is the calendar day's** (task 0151).
##
## - `day` is kept, and becomes the date: no version 4 build ever held a
##   day back, so the day a save is on is the date it is on.
## - `night` is left alone. A night in progress - saved in NIGHT, or in
##   RESULT with its report - keeps its number until it ends, and the
##   calendar takes over at the next `begin_night`; in DAY or PREPARATION
##   the next night is simply today's.
## - `nights_paid` keeps its entries and gains none. An old night number is
##   at most the nights won, which is below the day, so no date still ahead
##   can be one already paid; padding the list with the dates a loss skipped
##   would make `already_paid(56)` say a year was beaten that was not.
## - `endless` meant "past the ten" and now means "past the year", so it
##   goes back to false - the year carries the run on, and 0160 offers it
##   again - except on a save already past `Calendar.year_days()`, which
##   keeps it so it is not counted over the moment it loads.
static func _night_is_the_date_v4(previous: Dictionary) -> Dictionary:
	var state := previous.duplicate(true)
	if bool(state.get("endless", false)):
		state["endless"] = int(state.get("day", 1)) > Calendar.year_days()
	state["version"] = 5
	return state


## **5 to 6: the 1.0 farm** (task 0156), laid onto a save without moving
## anything on it:
##
## - **The cleared ground** - the spawn bands and the kept sites: a map tree
##   or rock leaves them only if it is untouched (no `hp` - nobody has swung
##   at it), and nothing there is left to regrow. Anything the player put
##   there, a plot or a chopped tree's stump stays.
## - **The new nodes and stumps**, where the save's cell is empty map ground:
##   no occupant, no plot, the terrain the map has there. A stump goes down
##   whole, on all four of its cells, or not at all.
## - Path caches reset and `grid_version` bumped, as the widenings do.
static func _farm_v1_0_from_v5(previous: Dictionary) -> Dictionary:
	var state := previous.duplicate(true)
	var occupants: Dictionary = state.get("occupants", {})
	var plots: Dictionary = state.get("plots", {})
	var terrain: PackedByteArray = state.get("terrain", PackedByteArray())
	if terrain.size() != Grid.CELLS:
		return {}
	var cleared := _ground_the_1_0_farm_clears()
	var regrowing: Array = state.get("regrowing", [])
	for idx in cleared:
		var on: Dictionary = occupants.get(idx, {})
		if not on.is_empty() and StringName(on["id"]) in [&"tree", &"rock"] \
				and not on.has("hp"):
			occupants.erase(idx)
		for entry in regrowing.duplicate():
			if int(entry[0]) == int(idx):
				regrowing.erase(entry)

	var fresh := Farm.initial()
	var fresh_occupants: Dictionary = fresh["occupants"]
	var fresh_terrain: PackedByteArray = fresh["terrain"]
	var keys: Array = fresh_occupants.keys()
	keys.sort()
	for idx in keys:
		var on: Dictionary = fresh_occupants[idx]
		if not StringName(on["id"]) in GameData.UNGATHERED_NODES:
			continue
		var anchor: Variant = on.get("anchor", null)
		var parts: Array = [int(idx)]
		if anchor != null:
			if Grid.index(Vector2i(int(anchor[0]), int(anchor[1]))) != int(idx):
				continue        # a stump goes down from its anchor, whole
			parts = []
			var size := Building.size_of(StringName(on["id"]))
			for y in size.y:
				for x in size.x:
					parts.append(Grid.index(Vector2i(int(anchor[0]) + x, int(anchor[1]) + y)))
		var room := true
		for part in parts:
			if occupants.has(part) or plots.has(part) \
					or terrain[int(part)] != fresh_terrain[int(part)]:
				room = false
		if not room:
			continue
		for part in parts:
			occupants[part] = (fresh_occupants[part] as Dictionary).duplicate(true)

	for key in Pathing.initial():
		state[key] = Pathing.initial()[key]
	for key in ["tower", "livestock"]:
		state[key + "_cells"] = []
		state[key + "_version"] = -1
	state["grid_version"] = int(state.get("grid_version", 0)) + 1
	state["version"] = 6
	return state


## Every cell the 1.0 farm keeps clear: the spawn bands and the sites.
static func _ground_the_1_0_farm_clears() -> Array:
	var out := {}
	for side in GameData.sorted_names(GameData.SPAWN_BANDS.keys()):
		for pair in (GameData.SPAWN_BANDS[side] as Array):
			out[Grid.index(Vector2i(int(pair[0]), int(pair[1])))] = true
	for id in GameData.sorted_names(GameData.MAP_SITES.keys()):
		var box: Array = GameData.MAP_SITES[id]
		for y in range(int(box[1]), int(box[1]) + int(box[3])):
			for x in range(int(box[0]), int(box[0]) + int(box[2])):
				out[Grid.index(Vector2i(x, y))] = true
	var cells: Array = out.keys()
	cells.sort()
	return cells


static func _room_to_expand(state: Dictionary, origin: Vector2i, size: Vector2i, old_parts: Array) -> bool:
	for y in size.y:
		for x in size.x:
			var cell := origin + Vector2i(x, y)
			if not Grid.in_bounds(cell) or state.get("plots", {}).has(Grid.index(cell)):
				return false
			if not old_parts.has(cell) and (not Farm.is_empty(state, cell) or Farm.UNBUILDABLE.has(Farm.terrain_at(state, cell))):
				return false
	var front := origin + Vector2i(size.x / 2, size.y)
	return Grid.in_bounds(front) and (Farm.walkable(state, front) or old_parts.has(front))


## **Version 9 (task 0189) puts the shipping bin by the porch**, where the
## save's cell is the empty map ground a new farm has there: no occupant, no
## plot, the same terrain. 0156 kept the site clear, so only something the
## player put there fills it - and then the farm keeps what it built and has
## no bin. Path caches reset and `grid_version` bumped, as the farm steps do.
static func _shipping_bin_v8(previous: Dictionary) -> Dictionary:
	var state := previous.duplicate(true)
	var occupants: Dictionary = state.get("occupants", {})
	var plots: Dictionary = state.get("plots", {})
	var terrain: PackedByteArray = state.get("terrain", PackedByteArray())
	if terrain.size() != Grid.CELLS:
		return {}
	var fresh := Farm.initial()
	var fresh_occupants: Dictionary = fresh["occupants"]
	var fresh_terrain: PackedByteArray = fresh["terrain"]
	var keys: Array = fresh_occupants.keys()
	keys.sort()
	for idx in keys:
		if StringName((fresh_occupants[idx] as Dictionary)["id"]) != Shipping.BIN:
			continue
		if occupants.has(idx) or plots.has(idx) or terrain[int(idx)] != fresh_terrain[int(idx)]:
			continue
		occupants[idx] = (fresh_occupants[idx] as Dictionary).duplicate(true)
	state["occupants"] = occupants
	for key in Pathing.initial():
		state[key] = Pathing.initial()[key]
	state["grid_version"] = int(state.get("grid_version", 0)) + 1
	state["version"] = 9
	return state


## And the same for the file format.
static func file_migrations() -> Dictionary:
	return {}


## Apply `table`'s migrations in order from `from_version` to `to_version`.
##
## Returns the brought-forward payload, or an **empty Dictionary** when there
## is a gap: a version with nothing to take it to the next one cannot be
## loaded, and guessing is how a save gets quietly corrupted instead of
## honestly refused.
##
## A pure function of its arguments, which is the point - `headless_check`
## drives it with a table of its own and watches the steps happen in order,
## so the driver is proven before anything depends on it.
static func step_up(payload: Dictionary, from_version: int, to_version: int,
		table: Dictionary) -> Dictionary:
	var carried := payload
	var v := from_version
	while v < to_version:
		if not table.has(v):
			push_warning("Save: no migration from version %d" % v)
			return {}
		var step: Callable = table[v]
		var next: Variant = step.call(carried)
		if typeof(next) != TYPE_DICTIONARY or (next as Dictionary).is_empty():
			push_warning("Save: the migration from version %d gave nothing" % v)
			return {}
		carried = next
		v += 1
	return carried


## FNV-1a over the payload. Enough to catch truncation, a flipped bit and a
## half-flushed write, which is what it is for; it is not a signature and does
## not pretend to be.
static func checksum(bytes: PackedByteArray) -> int:
	var h := _FNV_OFFSET
	for b in bytes:
		h = (h ^ b) & _MASK
		h = (h * _FNV_PRIME) & _MASK
	return h


static func _append_u32(buffer: PackedByteArray, value: int) -> void:
	for shift in [0, 8, 16, 24]:
		buffer.append((value >> shift) & 0xFF)


static func _read_u32(buffer: PackedByteArray, at: int) -> int:
	var v := 0
	for i in 4:
		v |= int(buffer[at + i]) << (i * 8)
	return v


static func _rename(from_path: String, to_path: String) -> bool:
	var dir := DirAccess.open(from_path.get_base_dir())
	if dir == null:
		push_error("Save: cannot open %s" % from_path.get_base_dir())
		return false
	var err := dir.rename(from_path.get_file(), to_path.get_file())
	if err != OK:
		push_error("Save: cannot put %s in place (error %d)" % [to_path, err])
		return false
	return true


static func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Version 7 converts old tick progress proportionally to whole growth days.
## The legacy durations are literals: future crop tuning must not alter them.
static func _crops_by_days_v6(previous: Dictionary) -> Dictionary:
	var state := previous.duplicate(true)
	var old_ticks := {&"carrot": 1800, &"wheat": 2700, &"corn": 5400}
	var days := {&"carrot": 3, &"wheat": 4, &"corn": 8}
	var plots: Dictionary = state.get("plots", {})
	var keys: Array = plots.keys()
	keys.sort()
	for idx in keys:
		var here: Dictionary = plots[idx]
		var crop := StringName(here.get("crop", &""))
		if old_ticks.has(crop):
			here["growth"] = clampi(int(here.get("growth", 0)), 0, int(old_ticks[crop])) * int(days[crop]) / int(old_ticks[crop])
		else:
			here["growth"] = 0
		here.erase("soak")
	state["version"] = 7
	return state


## **Version 8: the fish are species** (task 0179). The one `fish` a save
## held and had gained arrives as carp - the commonest when version 8 was
## written, and a literal so that re-weighting the pond later cannot move an
## old save. Reconcile alone would drop the key and the fish with it. A line
## in the water is reeled in empty; the last catch names its carp.
static func _fish_by_species_v7(previous: Dictionary) -> Dictionary:
	var state := previous.duplicate(true)
	for key in ["held", "gained"]:
		var table: Dictionary = state.get(key, {})
		# Matched by its text: an old key may have been written either way.
		for old in table.keys():
			if str(old) == "fish":
				var landed := int(table[old])
				table.erase(old)
				table[&"carp"] = int(table.get(&"carp", 0)) + landed
	state["fishing"] = {}
	var last: Dictionary = state.get("last_catch", {})
	if not last.is_empty():
		var landed := int((last.get("yield", {}) as Dictionary).get(&"fish", 1))
		state["last_catch"] = {"species": &"carp", "yield": {&"carp": landed}}
	state["version"] = 8
	return state
