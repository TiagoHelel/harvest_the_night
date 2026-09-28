extends Node

## Every sound in the game goes through here.
##
## Four buses and one way in: `Audio.play(&"sfx/shot")`. Tasks 0084 to 0087
## only have to drop files into `assets/sfx/`, `assets/music/` and
## `assets/ambience/` - **the folder a sound lives in is the bus it plays
## on**, so nothing is listed twice and nothing can be listed wrongly.
##
## ## Four buses, not the three the task asked for
##
## Task 0083 names Master, SFX and Music. `Settings.DEFAULTS` has had
## `audio/ambience` in it since task 0009 and task 0087 is the ambient bed -
## birds and water by day, wind and groaning by night. A fourth bus now costs
## four lines; a fourth bus later costs an options tab that has been shipping
## a slider which moves nothing. Said out loud in the journal rather than
## quietly counted as done.
##
## ## Nothing in here is a rule
##
## `src/app/` is services: nodes, disk, the audio server. `src/core/` cannot
## see this file and must not, because a sound that changed a rule would put
## the determinism guard at the mercy of a volume slider. Playing a sound
## returns a bool and writes nothing anybody can read back.
##
## ## Why it works outside the tree
##
## An autoload is only added to the root when a scene runs, so a headless
## check driving `--script` never sees one. Everything here works on a plain
## `Audio.new()` added to a tree by hand, with two caveats the checks rely on:
##
## - `_ready()` builds the voices and scans the folders. Call it or add the
##   node to a tree.
## - The same-frame dedupe is driven by `_process`, so a check that never
##   renders a frame has to call `frame_passed()` itself.

## Folder under `ROOT` -> the bus its sounds play on. The whole catalogue.
const BUSES := {
	&"sfx": &"SFX",
	&"music": &"Music",
	&"ambience": &"Ambience",
}

## The bus everything else sends to.
const MASTER := &"Master"

## Settings key -> the bus it turns down.
const VOLUME_KEYS := {
	&"audio/master": MASTER,
	&"audio/music": &"Music",
	&"audio/sfx": &"SFX",
	&"audio/ambience": &"Ambience",
}

const ROOT := "res://assets/"

## What a sound can be written as. Godot imports all three; which one a task
## picks is its business.
const EXTENSIONS: Array = [".wav", ".ogg", ".mp3"]

## How many sounds may be in the air at once.
##
## **Not a `# LEVER` in `game_data.gd`**, and not a `Settings` key either. It
## is not a rule, so it must not touch the data hash; and it is not something
## a player has an opinion about, unlike `video/max_particles`, which is a
## frame budget. Sixteen is four more than the most defences a farm has been
## seen to fire on one tick, and the dedupe below means twenty towers firing
## the same gun ask for one voice, not twenty.
const MAX_VOICES := 16

## At or below this a bus is **muted** rather than turned down. A bus at
## minus eighty decibels is quiet; the done-when says silent, and those are
## different things - a long music loop at -80dB is still audible on
## headphones in a quiet room.
const SILENCE := 0.001

const SettingsScript := preload("res://src/app/settings.gd")

## id -> AudioStream, filled by `_scan()` and by anything that generates one.
var _streams: Dictionary = {}

## id -> the frame it last started on, for the same-frame dedupe.
var _last_frame: Dictionary = {}

## Ids that have already been complained about, so a sound asked for every
## tick does not fill the log with the same line sixty times a second.
var _warned: Dictionary = {}

var _voices: Array = []
var _frame := 0

var _started := 0
var _deduped := 0
var _dropped := 0
var _warnings := 0


func _ready() -> void:
	build()


## Build the voices, read the folders and take the volumes off `Settings`.
##
## Separate from `_ready()` so a check can drive it by hand, and safe to call
## twice - the second call rebuilds nothing it already has.
func build() -> void:
	if _voices.is_empty():
		for i in MAX_VOICES:
			var voice := AudioStreamPlayer.new()
			voice.name = "Voice%02d" % i
			add_child(voice)
			_voices.append(voice)
	scan()
	var settings := _settings()
	if settings != null:
		if not settings.changed.is_connected(_on_setting_changed):
			settings.changed.connect(_on_setting_changed)
		if not settings.reloaded.is_connected(apply_volumes):
			settings.reloaded.connect(apply_volumes)
	apply_volumes()


func _process(_delta: float) -> void:
	_frame += 1


## Move the dedupe on by one frame.
##
## `_process` calls this when there is a tree. A headless check has no frames
## and calls it itself, which is also what makes "twenty on one tick" a thing
## that can be asked rather than hoped for.
func frame_passed() -> void:
	_frame += 1


# ------------------------------------------------------------------ the sound

## Play a sound. False when nothing was started, and never a crash.
##
## Four reasons nothing starts, in the order they are decided:
##
## 1. **The id is not one we have.** Warned about once and never again.
## 2. **It already started this frame.** Twenty towers firing on one tick is
##    one gunshot, not twenty stacked on top of each other six samples apart -
##    which is not twenty gunshots, it is a click and eighteen decibels of
##    headroom gone.
## 3. **Every voice is busy.** Dropped rather than stealing one mid-sound,
##    because a stolen voice is an audible cut.
## 4. Something is wrong with the stream itself.
func play(id: StringName) -> bool:
	var stream := _stream_for(id)
	if stream == null:
		if not _warned.has(id):
			_warned[id] = true
			_warnings += 1
			push_warning("Audio: nothing called '%s' - staying silent" % id)
		return false

	if int(_last_frame.get(id, -1)) == _frame:
		_deduped += 1
		return false
	# **Recorded before the voice is looked for**, not after. Otherwise a full
	# pool turns twenty towers firing on one tick into twenty drops instead of
	# one attempt and nineteen folded into it - the same sound asked for
	# twice in a frame is one sound whether or not there was room for it.
	_last_frame[id] = _frame

	var voice := _free_voice()
	if voice == null:
		_dropped += 1
		return false

	voice.bus = _bus_for(id)
	voice.stream = stream
	# **Told to play only when the tree will take it.** `AudioStreamPlayer`
	# errors with "playback can only happen when a node is inside the scene
	# tree" while the tree is still starting, which is exactly when a headless
	# check drives this by hand - and an engine error in the middle of a clean
	# suite is noise that trains people to ignore errors. The voice is still
	# allocated and still counted: `started()` means a voice was taken, and
	# whether a driver made a noise with it is the driver's business.
	if voice.is_inside_tree():
		voice.play()
	_started += 1
	return true


## Put a stream under an id.
##
## `scan()` calls this for every file it finds, and it is also how anything
## that **makes** a sound rather than loading one gets it in - task 0086's
## crossfade, and the checks, which have no files to point at because task
## 0084 is what brings them.
func add(id: StringName, stream: AudioStream) -> bool:
	if stream == null or _bus_for(id) == &"":
		push_error("Audio: '%s' is not a sound on a bus this game has" % id)
		return false
	_streams[id] = stream
	_warned.erase(id)           # it exists now; a past complaint is stale
	return true


## Everything in `assets/sfx`, `assets/music` and `assets/ambience`, by id.
##
## Missing folders are not an error: this ships before task 0084 writes the
## first WAV, and a game with no sounds yet should start in silence rather
## than refuse to start.
func scan() -> int:
	var found := 0
	for folder in BUSES:
		var path := ROOT + str(folder) + "/"
		var dir := DirAccess.open(path)
		if dir == null:
			continue
		var names: Array = []
		for file_name in dir.get_files():
			# An exported build has no `.import` sidecars, a development one
			# does. Strip it and let the name underneath decide.
			var clean := file_name
			if clean.ends_with(".import"):
				clean = clean.substr(0, clean.length() - 7)
			if not names.has(clean):
				names.append(clean)
		names.sort()            # a fixed order; these are Strings, not names
		for entry in names:
			var file_name := String(entry)
			var ext := "." + file_name.get_extension()
			if not EXTENSIONS.has(ext):
				continue
			var full := path + file_name
			if not ResourceLoader.exists(full):
				continue
			var stream: AudioStream = load(full)
			if stream == null:
				continue
			var id := StringName("%s/%s" % [folder,
				file_name.get_basename()])
			_streams[id] = stream
			found += 1
	return found


func stop_all() -> void:
	for voice in _voices:
		(voice as AudioStreamPlayer).stop()
	_last_frame.clear()


# ---------------------------------------------------------------- the volumes

## Put every bus where `Settings` says it should be.
##
## **Zero mutes rather than turns down**, and `audio/muted` mutes Master,
## which everything sends to - so one flag silences the music as well as the
## shots. That is the done-when, and it is why the buses are wired as a tree
## rather than as four independent outputs.
func apply_volumes() -> void:
	var muted := _bool_setting(&"audio/muted")
	var keys: Array = VOLUME_KEYS.keys()
	keys.sort()             # a fixed order, and these are Strings underneath
	for key in keys:
		var bus: StringName = VOLUME_KEYS[key]
		var index := AudioServer.get_bus_index(String(bus))
		if index < 0:
			push_error("Audio: no bus called '%s' - is "
				% bus + "default_bus_layout.tres still there?")
			continue
		var level := _float_setting(key)
		var silent := is_silent(level, muted, bus)
		AudioServer.set_bus_mute(index, silent)
		AudioServer.set_bus_volume_db(index,
			0.0 if silent else linear_to_db(level))


## Whether a bus should be silent, given its level and the mute flag.
##
## Pulled out of `apply_volumes()` so it can be asked directly rather than
## inferred from the state of the audio server: a check with no `Settings`
## autoload can still test the rule, which is the part that has decisions in
## it.
##
## **`muted` only silences Master.** It does not mute the other three, and it
## does not have to: they send to Master, so one flag takes the music down
## with the shots. Muting each of them instead would leave a fourth bus
## somebody adds in a year quietly still playing.
static func is_silent(level: float, muted: bool, bus: StringName) -> bool:
	return level <= SILENCE or (muted and bus == MASTER)


func _on_setting_changed(key: StringName) -> void:
	if VOLUME_KEYS.has(key) or key == &"audio/muted":
		apply_volumes()


# ------------------------------------------------------------------ the counts

## How many voices are in the air. What the polyphony cap is asked about.
func voices_playing() -> int:
	var n := 0
	for voice in _voices:
		if (voice as AudioStreamPlayer).playing:
			n += 1
	return n


func voice_count() -> int:
	return _voices.size()


func known_ids() -> Array:
	return GameData.sorted_names(_streams.keys())


## Sounds actually started, sounds folded into one because they asked twice in
## a frame, sounds dropped because every voice was busy, and ids complained
## about. The checks read these rather than listening.
func started() -> int:
	return _started


func deduped() -> int:
	return _deduped


func dropped() -> int:
	return _dropped


func warnings() -> int:
	return _warnings


func forget_counts() -> void:
	_started = 0
	_deduped = 0
	_dropped = 0


# ------------------------------------------------------------------- privately

func _stream_for(id: StringName) -> AudioStream:
	return _streams.get(id, null)


## The bus an id plays on, off the folder in front of the slash. Empty when
## the id is not of that shape, which is what makes `add()` refuse it.
func _bus_for(id: StringName) -> StringName:
	var parts := String(id).split("/", true, 1)
	if parts.size() != 2 or parts[1] == "":
		return &""
	return BUSES.get(StringName(parts[0]), &"")


func _free_voice() -> AudioStreamPlayer:
	for voice in _voices:
		var player := voice as AudioStreamPlayer
		if not player.playing:
			return player
	return null


## The `Settings` autoload, **by path and never by name**.
##
## `verify.py` parses every script on its own with no autoloads registered, so
## a bare `Settings.get_float(...)` is an undeclared identifier there and the
## parse row goes red for a file that is perfectly correct at runtime.
func _settings() -> Node:
	# `get_tree()` itself errors with "Parameter data.tree is null" when the
	# node is not in a tree, so the cheap question goes first.
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	# **Through the root rather than as an absolute path.** `get_node_or_null`
	# with "/root/Settings" errors with "can't use absolute paths from outside
	# the active scene tree" while the tree is still starting - which is
	# exactly when a headless check builds one of these by hand.
	return tree.root.get_node_or_null(^"Settings")


func _float_setting(key: StringName) -> float:
	var settings := _settings()
	if settings != null:
		return float(settings.get_float(key))
	return float(SettingsScript.DEFAULTS.get(key, 1.0))


func _bool_setting(key: StringName) -> bool:
	var settings := _settings()
	if settings != null:
		return bool(settings.get_bool(key))
	return bool(SettingsScript.DEFAULTS.get(key, false))
