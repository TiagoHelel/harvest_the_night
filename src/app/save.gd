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
## **Empty, and that is the honest answer.** The state has been version 1 for
## the whole of this project. The driver under it is not empty, and is
## checked against a table `headless_check` supplies, because the moment
## there is a real migration is the worst moment to find out the machinery
## that runs them was never exercised.
static func migrations() -> Dictionary:
	return {}


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
