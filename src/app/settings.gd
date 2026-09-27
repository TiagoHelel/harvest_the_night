extends Node

## Everything the player can change about how the game presents itself.
##
## One place that owns it and writes it to `user://settings.cfg`, so the options
## menus of tasks 0093 to 0095 only read and write here and no panel has to
## remember to persist anything.
##
## **Nothing in here may reach the simulation.** These are presentation and
## comfort: volume, window mode, shake, language, key bindings. A setting that
## changed a rule would mean two players with different options playing
## different games, and would put the determinism guard at the mercy of a
## slider. `src/core/` cannot see this file, which is why it lives in
## `src/app/`.
##
## ## Why it can be instantiated outside the tree
##
## An autoload in Godot is only added to the root when a scene runs, so a
## headless check driving `--script` would never see one. Every method here
## works on a plain `Settings.new()` with `load_from_disk()` called by hand,
## which is how `headless_check` tests the missing-file and corrupt-file paths
## the prompt asks about. `_ready()` does nothing but call that.

## Emitted for the one key that changed, so a panel updates the control it owns
## instead of rebuilding itself.
signal changed(key: StringName)

## Emitted once after a load, when every value may have changed at once.
signal reloaded

const PATH := "user://settings.cfg"
const TEMP_PATH := "user://settings.cfg.tmp"

## Bumped when a key is renamed, removed or changes meaning. `_migrate()` is
## where the corresponding fix-up goes.
const VERSION := 1

## **The one list.** A key that is not here does not exist: it cannot be read,
## cannot be written, and is dropped from a file that has it. That is what stops
## a stale key from a two-versions-ago build quietly surviving forever.
##
## Grouped by prefix - `video/`, `audio/`, `gameplay/`, `a11y/`, `controls/` -
## which is how `group()` slices them for the four options tabs.
const DEFAULTS := {
	&"video/window_mode": 0,            # 0 windowed, 1 borderless, 2 fullscreen
	&"video/scale": 3,                  # integer multiple of 480x270
	&"video/integer_scaling": true,
	&"video/vsync": true,
	&"video/max_fps": 0,                # 0 is uncapped

	&"audio/master": 1.0,
	&"audio/music": 0.8,
	&"audio/sfx": 1.0,
	&"audio/ambience": 0.7,
	&"audio/muted": false,

	&"gameplay/language": "en",
	&"gameplay/night_speed": 1,
	&"gameplay/skip_transition": false,
	&"gameplay/tutorial_seen": false,

	&"a11y/screen_shake": 1.0,
	&"a11y/flashing": true,
	&"a11y/particle_density": 1.0,
	&"a11y/ui_scale": 1.0,
	&"a11y/high_contrast": false,

	&"controls/bindings": {},           # task 0095 fills this
}

var _values: Dictionary = {}
var _loaded_from_defaults := false


func _ready() -> void:
	load_from_disk()


# ------------------------------------------------------------------- reading

## The value of a key, or its default. An unknown key is a mistake at the call
## site and says so rather than returning null for someone to trip over later.
func get_value(key: StringName) -> Variant:
	if not DEFAULTS.has(key):
		push_error("Settings: unknown key '%s'" % key)
		return null
	return _values.get(key, DEFAULTS[key])


func get_bool(key: StringName) -> bool:
	return bool(get_value(key))


func get_int(key: StringName) -> int:
	return int(get_value(key))


func get_float(key: StringName) -> float:
	return float(get_value(key))


func get_string(key: StringName) -> String:
	return str(get_value(key))


func get_dict(key: StringName) -> Dictionary:
	var v: Variant = get_value(key)
	return v if v is Dictionary else {}


## Every key in one group, as `{key: value}`. `group(&"audio")` is the four
## sliders and the mute, which is exactly one options tab.
func group(prefix: StringName) -> Dictionary:
	var out := {}
	var keys: Array = DEFAULTS.keys()
	keys.sort()
	for key in keys:
		if str(key).begins_with(str(prefix) + "/"):
			out[key] = get_value(key)
	return out


## True when the last load fell back to defaults - a missing file, or one that
## would not parse. The title screen uses it to say so once.
func loaded_from_defaults() -> bool:
	return _loaded_from_defaults


# ------------------------------------------------------------------- writing

## Set a key and persist it. Setting a key to what it already is does nothing
## and emits nothing, so a panel writing on every frame of a slider drag does
## not write the disk sixty times a second.
func set_value(key: StringName, value: Variant, persist: bool = true) -> void:
	if not DEFAULTS.has(key):
		push_error("Settings: unknown key '%s'" % key)
		return
	if typeof(value) != typeof(DEFAULTS[key]):
		push_error("Settings: '%s' wants %s, got %s"
			% [key, type_string(typeof(DEFAULTS[key])), type_string(typeof(value))])
		return
	if get_value(key) == value:
		return
	_values[key] = value
	changed.emit(key)
	if persist:
		save()


## Put one key, or everything, back to the shipped default.
func reset(key: StringName = &"") -> void:
	if key == &"":
		_values.clear()
		save()
		reloaded.emit()
		return
	if not DEFAULTS.has(key):
		push_error("Settings: unknown key '%s'" % key)
		return
	if _values.erase(key):
		changed.emit(key)
		save()


# ---------------------------------------------------------- disk, carefully

## Read the file, or fall back to the defaults and say so.
##
## Three things can be wrong and none of them may crash: the file is missing
## (first run), the file will not parse (a crash mid-write, a bad edit, a disk
## that lied), or the file is from an older version. The first two land on
## defaults with a line in the log; the third goes through `_migrate()`.
func load_from_disk() -> void:
	_values.clear()
	_loaded_from_defaults = false

	var path := _recover_path()
	if path.is_empty():
		_loaded_from_defaults = true
		print("Settings: no file at %s, starting on defaults" % PATH)
		reloaded.emit()
		return

	var cfg := ConfigFile.new()
	var err := cfg.load(path)
	if err != OK:
		_loaded_from_defaults = true
		push_warning("Settings: %s is unreadable (error %d) - starting on "
			% [path, err] + "defaults. The bad file is left where it is.")
		reloaded.emit()
		return

	# **`ConfigFile.load()` succeeding does not mean the file was ours.** Godot's
	# parser is lenient: hand it a line of rubbish and it will happily read the
	# first bracketed run as a section name and return OK. Measured, not
	# assumed - a corrupt file was reaching this point with `err == OK` and the
	# game would then have come up on defaults without ever saying why.
	#
	# Every file this class writes has `[meta] version`. One that does not was
	# not written by this class, so it is treated as corrupt.
	if not cfg.has_section_key("meta", "version"):
		_loaded_from_defaults = true
		push_warning("Settings: %s has no version - it was not written by "
			% path + "this game, or it is damaged. Starting on defaults and "
			+ "leaving the file where it is.")
		reloaded.emit()
		return

	var file_version := int(cfg.get_value("meta", "version", 0))
	var raw := {}
	for section in cfg.get_sections():
		if section == "meta":
			continue
		for key in cfg.get_section_keys(section):
			raw[StringName("%s/%s" % [section, key])] = cfg.get_value(section, key)

	if file_version != VERSION:
		raw = _migrate(raw, file_version)

	# **An unknown key is dropped, not kept.** A key from a build two versions
	# ago that nothing reads any more would otherwise sit in the file forever,
	# and the day its name is reused it would come back as a surprise.
	var dropped: Array = []
	var keys: Array = raw.keys()
	keys.sort()
	for key in keys:
		if not DEFAULTS.has(key):
			dropped.append(str(key))
			continue
		if typeof(raw[key]) != typeof(DEFAULTS[key]):
			dropped.append("%s (wrong type)" % key)
			continue
		_values[key] = raw[key]
	if not dropped.is_empty():
		push_warning("Settings: dropped %s" % ", ".join(dropped))

	reloaded.emit()


## Write the file so that a crash halfway through cannot destroy it.
##
## The config is written to a temporary file first and only then put in place.
## Windows will not rename onto an existing file, so the old one is removed
## first - which leaves a window where neither exists. `_recover_path()` closes
## it: a crash in that window leaves the temporary file, and the next load
## picks it up instead of falling back to defaults.
func save() -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", VERSION)
	var keys: Array = _values.keys()
	keys.sort()
	for key in keys:
		var parts := str(key).split("/", true, 1)
		cfg.set_value(parts[0], parts[1], _values[key])

	var err := cfg.save(TEMP_PATH)
	if err != OK:
		push_error("Settings: could not write %s (error %d)" % [TEMP_PATH, err])
		return false

	var dir := DirAccess.open("user://")
	if dir == null:
		push_error("Settings: cannot open user:// to place the file")
		return false
	if dir.file_exists(PATH.get_file()):
		dir.remove(PATH.get_file())
	err = dir.rename(TEMP_PATH.get_file(), PATH.get_file())
	if err != OK:
		push_error("Settings: could not put %s in place (error %d)" % [PATH, err])
		return false
	return true


## Which file to read: the real one, or the temporary one left by a crash
## between removing the old file and renaming the new one into place.
func _recover_path() -> String:
	if FileAccess.file_exists(PATH):
		return PATH
	if FileAccess.file_exists(TEMP_PATH):
		push_warning("Settings: recovering %s, which a previous run left behind"
			% TEMP_PATH)
		return TEMP_PATH
	return ""


## Bring an older file forward. One `if` per version bump, applied in order.
##
## Nothing to do yet - VERSION is 1 and there has never been a 0 in the wild -
## but the shape is here so the first rename has somewhere obvious to go, and
## `headless_check` covers the unknown-version path today.
func _migrate(raw: Dictionary, from_version: int) -> Dictionary:
	if from_version < 1:
		# A file with no version field at all: pre-release, keep what matches.
		push_warning("Settings: file has no version, treating it as 1")
	if from_version > VERSION:
		push_warning("Settings: file is from a newer build (version %d) - "
			% from_version + "keeping only the keys this build knows")
	return raw
