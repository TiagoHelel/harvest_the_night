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
	return _write(RUN_PATH, {"state": state})


## Read the game in progress, or an empty Dictionary when there is not one, or
## when the file is damaged. **Never crashes and never half-loads**: a bad file
## leaves the caller with nothing, which it can tell from a good one.
static func read_run() -> Dictionary:
	var payload := _read(RUN_PATH)
	if payload.is_empty():
		return {}
	var state: Dictionary = payload.get("state", {})
	if state.is_empty() or not state.has("tick"):
		push_warning("Save: %s parsed but holds no game" % RUN_PATH)
		return {}
	return state


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
		push_warning("Save: %s is %d bytes, too short to be a save"
			% [path, raw.size()])
		return {}
	if raw.slice(0, 4).get_string_from_ascii() != MAGIC:
		push_warning("Save: %s is not a %s save file" % [path, MAGIC])
		return {}

	var version := _read_u32(raw, 4)
	var length := _read_u32(raw, 8)
	var sum := _read_u32(raw, 12)
	var body := raw.slice(HEADER)

	if body.size() != length:
		push_warning("Save: %s claims %d bytes of payload and has %d - it was "
			% [path, length, body.size()] + "truncated")
		return {}
	if checksum(body) != sum:
		push_warning("Save: %s is damaged - the checksum does not match" % path)
		return {}

	if version > FORMAT_VERSION:
		push_warning("Save: %s is format %d and this build understands %d"
			% [path, version, FORMAT_VERSION])
		return {}

	var payload: Variant = bytes_to_var(body)
	if typeof(payload) != TYPE_DICTIONARY:
		push_warning("Save: %s decoded to a %s, not a save"
			% [path, type_string(typeof(payload))])
		return {}

	if version < FORMAT_VERSION:
		payload = _migrate(payload, version)
	return payload


## Bring an older file forward, one step per version, in order.
##
## Nothing to do yet - there has only ever been format 1 - but the shape is
## here so the first change has one obvious place to go, and `headless_check`
## already covers the from-the-future and the too-old paths.
static func _migrate(payload: Dictionary, from_version: int) -> Dictionary:
	var v := from_version
	while v < FORMAT_VERSION:
		match v:
			_:
				push_warning("Save: no migration from format %d, keeping what "
					% v + "this build recognises")
		v += 1
	return payload


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
