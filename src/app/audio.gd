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

## How long a crossfade takes when nobody says. **Overridden in practice**:
## `Music` hands it the transition's own length, so the music changes exactly
## as the screen does.
const FADE_SECONDS := 1.6

## How far a sound effect's pitch may wander, either way.
##
## **Repetition is the enemy of a cozy game.** Chopping one tree is twenty
## swings and a player will hear the same three hundred milliseconds twenty
## times in a minute; identical every time, it stops being wood and starts
## being a sample. Six per cent is enough that no two are the same and small
## enough that none of them sounds wrong - past about a tenth the low notes
## start reading as a different axe.
##
## **Only the SFX bus.** Music and ambience are long and tonal, and a loop
## that came back a semitone out would be the most noticeable thing in the
## game. `tools/gen_sfx.py` reads this number out of this file rather than
## keeping its own copy, so the minute of chopping it renders for a person to
## listen to is the minute the game actually plays.
const PITCH_JITTER := 0.06

## Where a sound has no position, and is played at full volume wherever the
## listener is. UI noises, and the Giant's roar, which is meant to carry.
const NOWHERE := Vector2(1e12, 1e12)

## Inside this many pixels a sound is at full volume. About a tile and a half:
## anything the player is standing on top of is simply loud.
const NEAR := 24.0

## Past this it is as quiet as it gets. Four hundred and eighty is the width
## of the screen, so **a thing you can see is a thing you can hear**, and the
## far fence of a six-hundred-and-forty pixel farm is at the floor.
const EARSHOT := 480.0

## How quiet the far side of the farm is. **Not silent.** A wave chewing
## through the fence you are not standing at is the thing you most need to be
## told about, and a falloff that muted it would be a falloff that hid it.
const FAR_FLOOR := 0.3

## Drawn from the global RNG, never the run's.
##
## A pitch is not a rule. `src/core/` owns one seeded stream and everything
## that touches it moves the determinism hash, so a sound that drew from it
## would make two players with different volume settings play different games.
## Same argument as the sparks in `particles.gd`.
const PITCH_SEED := 84084

## At or below this a bus is **muted** rather than turned down. A bus at
## minus eighty decibels is quiet; the done-when says silent, and those are
## different things - a long music loop at -80dB is still audible on
## headphones in a quiet room.
const SILENCE := 0.001

const SettingsScript := preload("res://src/app/settings.gd")

## id -> AudioStream, filled by `_scan()` and by anything that generates one.
var _streams: Dictionary = {}

## id -> the frame it last started on, for the dedupe and the gap.
var _last_frame: Dictionary = {}

## Where the ears are. The view sets it; `NOWHERE` until something does, which
## makes every positioned sound full volume rather than silent - the safe way
## round for a listener nobody remembered to place.
var _ears := NOWHERE

## Ids that have already been complained about, so a sound asked for every
## tick does not fill the log with the same line sixty times a second.
var _warned: Dictionary = {}

var _voices: Array = []
var _frame := 0

## **The music deck, which is not the voice pool.** Two slots that crossfade
## into each other and one layer that sits over the top. Separate because a
## ninety-six second loop taking one of sixteen shared voices - and never
## giving it back - would be a gunshot lost every time the music started.
var _deck: Array = []
var _layer: AudioStreamPlayer = null
var _playing := &""
var _layer_id := &""
var _fades: Array = []

## Its own generator rather than the global one, so that seeding the globals -
## which `src/tools/shot.gd` does to make the smoke reproducible - does not
## also decide what the next gunshot sounds like.
var _pitch := RandomNumberGenerator.new()

var _last_played := &""

## id -> how many times it has taken a voice.
var _plays: Dictionary = {}

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
	_pitch.seed = PITCH_SEED
	if _voices.is_empty():
		for i in MAX_VOICES:
			var voice := AudioStreamPlayer.new()
			voice.name = "Voice%02d" % i
			add_child(voice)
			_voices.append(voice)
	if _deck.is_empty():
		for i in 2:
			var slot := AudioStreamPlayer.new()
			slot.name = "Music%d" % i
			slot.bus = BUSES[&"music"]
			slot.volume_db = linear_to_db(0.0)
			add_child(slot)
			_deck.append(slot)
			_fades.append([0.0, 0.0, 0.0, 0.0])  # from, to, left, length
		_layer = AudioStreamPlayer.new()
		_layer.name = "MusicLayer"
		_layer.bus = BUSES[&"music"]
		_layer.volume_db = linear_to_db(0.0)
		add_child(_layer)
		_fades.append([0.0, 0.0, 0.0, 0.0])
	scan()
	var settings := _settings()
	if settings != null:
		if not settings.changed.is_connected(_on_setting_changed):
			settings.changed.connect(_on_setting_changed)
		if not settings.reloaded.is_connected(apply_volumes):
			settings.reloaded.connect(apply_volumes)
	apply_volumes()


func _process(delta: float) -> void:
	_frame += 1
	_advance_fades(delta)


## Put the ears somewhere. The camera follows the farmer, so this is the
## farmer - which is also the answer a player would give if asked where they
## are standing.
func listen_at(where: Vector2) -> void:
	_ears = where


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
## 2. **It started too recently.** `gap` frames is the shortest allowed
##    distance between two plays of the same id. One - the default - means
##    "not twice in a frame", which is twenty towers firing on one tick
##    becoming one gunshot rather than twenty stacked six samples apart. A
##    bigger gap is what stops fifty zombies becoming weather.
## 3. **Every voice is busy.** Dropped rather than stealing one mid-sound,
##    because a stolen voice is an audible cut.
## 4. Something is wrong with the stream itself.
func play(id: StringName, at: Vector2 = NOWHERE, gap: int = 1) -> bool:
	var stream := _stream_for(id)
	if stream == null:
		if not _warned.has(id):
			_warned[id] = true
			_warnings += 1
			push_warning("Audio: nothing called '%s' - staying silent" % id)
		return false

	if _frame - int(_last_frame.get(id, -1000000)) < maxi(gap, 1):
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

	var bus := _bus_for(id)
	voice.bus = bus
	voice.stream = stream
	voice.pitch_scale = _jitter(bus)
	voice.volume_db = linear_to_db(loudness(_ears, at))
	# **Told to play only when the tree will take it.** `AudioStreamPlayer`
	# errors with "playback can only happen when a node is inside the scene
	# tree" while the tree is still starting, which is exactly when a headless
	# check drives this by hand - and an engine error in the middle of a clean
	# suite is noise that trains people to ignore errors. The voice is still
	# allocated and still counted: `started()` means a voice was taken, and
	# whether a driver made a noise with it is the driver's business.
	if voice.is_inside_tree():
		voice.play()
	_last_played = id
	_plays[id] = int(_plays.get(id, 0)) + 1
	_started += 1
	return true


# ------------------------------------------------------------------ the music

## What is playing, or `&""`. The controller asks before it decides.
func music_playing() -> StringName:
	return _playing


func layer_playing() -> StringName:
	return _layer_id


## Start a piece, crossfading out whatever was on.
##
## **Asking for what is already playing does nothing**, which is what lets the
## controller say what it wants every frame without restarting the loop sixty
## times a second.
func play_music(id: StringName, seconds: float = FADE_SECONDS) -> bool:
	if id == _playing:
		return false
	if id != &"" and _stream_for(id) == null:
		if not _warned.has(id):
			_warned[id] = true
			_warnings += 1
			push_warning("Audio: no music called '%s'" % id)
		return false

	var free_slot := 0 if _level_of(0) <= _level_of(1) else 1
	var busy_slot := 1 - free_slot
	_fade_to(busy_slot, 0.0, seconds)
	if id == &"":
		_playing = &""
		return true

	var slot := _deck[free_slot] as AudioStreamPlayer
	slot.stream = _looping(_stream_for(id))
	slot.volume_db = linear_to_db(0.0)
	if slot.is_inside_tree():
		slot.play()
	_fade_to(free_slot, 1.0, seconds)
	_playing = id
	return true


## Bring the urgent layer in or take it out. It sits **over** the piece rather
## than replacing it, so the last wave changes what the night sounds like
## without stopping and starting it.
func set_layer(id: StringName, seconds: float = FADE_SECONDS) -> bool:
	if id == _layer_id:
		return false
	if id == &"":
		_layer_id = &""
		_fade_to(2, 0.0, seconds)
		return true
	if _stream_for(id) == null:
		return false
	if _layer != null:
		_layer.stream = _looping(_stream_for(id))
		_layer.volume_db = linear_to_db(0.0)
		if _layer.is_inside_tree():
			_layer.play()
	_layer_id = id
	_fade_to(2, 1.0, seconds)
	return true


## How loud one deck slot is, 0 to 1. The checks read it to watch a crossfade
## happen rather than to be told that one did.
func music_level(slot: int) -> float:
	return _level_of(slot)


## **Looping, set here rather than on the import.** Godot's WAV importer has
## an `edit/loop_mode`, and an `.import` file is generated - a setting that
## would come back the next time somebody reimported. This is a line of code
## that cannot be undone by a tool.
func _looping(stream: AudioStream) -> AudioStream:
	var wav := stream as AudioStreamWAV
	if wav != null and wav.loop_mode != AudioStreamWAV.LOOP_FORWARD:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
	return stream


func _player_of(slot: int) -> AudioStreamPlayer:
	if slot < _deck.size():
		return _deck[slot] as AudioStreamPlayer
	return _layer


func _level_of(slot: int) -> float:
	var player := _player_of(slot)
	if player == null:
		return 0.0
	return db_to_linear(player.volume_db)


## Start a fade. The record is where it came from, where it is going, how
## much is left and how long it was - **the last of those is the one the first
## version forgot**, and without it the curve is computed against a shrinking
## denominator and lands early.
func _fade_to(slot: int, target: float, seconds: float) -> void:
	if slot >= _fades.size():
		return
	var length := maxf(seconds, 0.0)
	_fades[slot] = [_level_of(slot), target, length, length]
	if length <= 0.0:
		_set_level(slot, target)


func _set_level(slot: int, level: float) -> void:
	var player := _player_of(slot)
	if player == null:
		return
	player.volume_db = linear_to_db(clampf(level, 0.0, 1.0))
	if level <= 0.0 and player.playing:
		player.stop()


func _advance_fades(delta: float) -> void:
	for slot in _fades.size():
		var fade: Array = _fades[slot]
		var left := float(fade[2])
		if left <= 0.0:
			continue
		left = maxf(left - delta, 0.0)
		fade[2] = left
		# Linear in amplitude, from where it started to where it is going.
		var total := maxf(float(fade[3]), 0.0001)
		var done := clampf(1.0 - left / total, 0.0, 1.0)
		_set_level(slot, lerpf(float(fade[0]), float(fade[1]), done))


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
		var player := voice as AudioStreamPlayer
		player.stop()
		player.volume_db = 0.0
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


## How loud something at `at` is to ears at `ears`.
##
## Its own function, and a static one, for the reason `is_silent` is: the rule
## is the part with a decision in it, and a check should be able to ask it
## straight rather than infer it from a voice's volume. Linear between `NEAR`
## and `EARSHOT` rather than inverse-square, because inverse-square is right
## for a point source in open air and wrong for a game that wants the far
## fence audible - physics is not the brief here, legibility is.
static func loudness(ears: Vector2, at: Vector2) -> float:
	if at == NOWHERE or ears == NOWHERE:
		return 1.0
	var distance := ears.distance_to(at)
	if distance <= NEAR:
		return 1.0
	if distance >= EARSHOT:
		return FAR_FLOOR
	var across := (distance - NEAR) / (EARSHOT - NEAR)
	return 1.0 - (1.0 - FAR_FLOOR) * across


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


## The last id that actually took a voice.
##
## For checks that need to know *which* sound happened rather than that one
## did - "chopping made a chop" is a different claim from "chopping made a
## noise", and on a farm with a dozen things ticking it is the only one worth
## asserting.
func last_played() -> StringName:
	return _last_played


## How many times one id has taken a voice since the counts were last
## forgotten. `started()` answers "did anything happen"; on a farm with a
## dozen things ticking, this answers the question worth asking.
func plays_of(id: StringName) -> int:
	return int(_plays.get(id, 0))


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
	_plays.clear()
	_last_played = &""
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


## A pitch a little either side of one, for an effect; exactly one for
## anything long and tonal.
func _jitter(bus: StringName) -> float:
	if bus != BUSES[&"sfx"]:
		return 1.0
	return 1.0 + PITCH_JITTER * (_pitch.randf() * 2.0 - 1.0)


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
