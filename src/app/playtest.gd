class_name Playtest

## A build to put in front of somebody, and a record of what they did with it.
##
## Off in every shipping build and on in one, by a feature tag the export
## preset sets. Nothing here runs at all when it is off: `is_on()` is the
## first line of every entry point, so a release build carries the code and
## never opens a file.
##
## ## The log is a local file, and that is the whole of it
##
## It is written to `user://playtest/`, it is plain text, and **nothing sends
## it anywhere**. The tester reads it, decides whether they are happy with it,
## and sends it or does not. Task 0103 made that promise about crash reports
## and asserted it with a grep over the whole of `src/`; the same grep covers
## this, and the same reasoning applies twice as hard to a file about how
## somebody played.
##
## ## What it records, and why that list
##
## The four questions a playtest has to answer are in the task: how far they
## got, how long a day took them, what they built, and where the run ended.
## Three of the four are already in the state - `Events` has been recording
## what happened since task 0090 and `stats.built_by_kind` counts what went
## down - so this is mostly a matter of putting a wall clock beside facts the
## rules already keep. **The rules are not changed to make this work**, which
## is why the determinism hash does not move for a task that adds a whole
## build flavour.
##
## ## The note key leaves a marker, not a sentence
##
## There is no text box in this game and there is not going to be one: task
## 0103's privacy check asserts there is no `LineEdit` anywhere in `src/`,
## because that is what makes "your name is not in the report" true by
## construction rather than by promise. So the feedback key writes a
## **numbered marker** - note 1, note 2 - and the tester says what note 3 was
## about afterwards, in whatever they are writing back to you. One key press
## in the middle of a fight is also a great deal more likely to happen than a
## typed sentence.

## Where session logs go.
const DIR := "user://playtest"

## The feature tag the playtest export preset sets. `OS.has_feature` is how a
## build tells you what kind of build it is.
const FLAG := "playtest"

## The key that leaves a marker. **Not a rebindable action.** Everything in
## `InputActions.ACTIONS` shows up on the controls screen, and an entry that
## does nothing in the build a player has is exactly the greyed-out button
## this project keeps refusing to draw. A playtest affordance is not a game
## control.
const NOTE_KEY := KEY_F1

## Turned on by hand, for a run from source and for the checks.
static var _forced := false

## The session: where it is being written and when it started.
static var _path := ""
static var _began_ms := 0
static var _notes := 0

## The tick of the last event written, so the same one is not written twice.
static var _seen := 0

## What the last frame saw, to notice a day or a phase turning over.
static var _day := 0
static var _phase := -1


## Whether this is a playtest build.
##
## The feature tag, or `--playtest` on the command line so that a run from
## source can be one without exporting anything.
static func is_on() -> bool:
	if _forced or OS.has_feature(FLAG):
		return true
	return OS.get_cmdline_args().has("--playtest") \
		or OS.get_cmdline_user_args().has("--playtest")


## Turn it on or off by hand. The checks use this; so does `--playtest`.
static func force(on: bool) -> void:
	_forced = on


## Start a session log for this run. Returns its path, or "".
static func begin(state: Dictionary) -> String:
	if not is_on():
		return ""
	# **Said from this session's point of view, not the next one's.** It
	# first read "a new run began", which in the summary came out as
	# `ended  a new run began` - which is the cause and not the ending, and
	# reads as though the run ended by starting.
	end_session("the tester started another run")
	if DirAccess.make_dir_recursive_absolute(DIR) != OK \
			and not DirAccess.dir_exists_absolute(DIR):
		return ""

	var when := Time.get_datetime_dict_from_system()
	var stamp := "%04d%02d%02d-%02d%02d%02d" % [int(when["year"]),
		int(when["month"]), int(when["day"]), int(when["hour"]),
		int(when["minute"]), int(when["second"])]
	# **Counted, because two runs in one second are two runs.** A check
	# starts a second one immediately and a tester restarting after ten
	# seconds of a bad first impression is the most interesting session
	# there is; either would have overwritten the other.
	_path = DIR.path_join("session-%s.log" % stamp)
	var nth := 2
	while FileAccess.file_exists(_path) and nth < 100:
		_path = DIR.path_join("session-%s-%d.log" % [stamp, nth])
		nth += 1
	_began_ms = Time.get_ticks_msec()
	_notes = 0
	_seen = 0
	_day = 0
	_phase = -1

	var f := FileAccess.open(_path, FileAccess.WRITE)
	if f == null:
		_path = ""
		return ""
	f.store_line("HARVEST THE NIGHT - playtest log")
	f.store_line("build   %s" % BuildInfo.line())
	f.store_line("seed    %d" % int(state.get("seed", 0)))
	f.store_line("began   %04d-%02d-%02d %02d:%02d"
		% [int(when["year"]), int(when["month"]), int(when["day"]),
			int(when["hour"]), int(when["minute"])])
	f.store_line("")
	f.store_line("This file is on your machine and was sent nowhere. It is")
	f.store_line("what you did and how long it took, and no more than that:")
	f.store_line("no name, no addresses, nothing from outside this game's")
	f.store_line("folder. Read it before you send it. NOTE lines are the")
	f.store_line("ones you left with %s."
		% OS.get_keycode_string(NOTE_KEY))
	f.store_line("")
	f.close()
	_write("the run began")
	return _path


## Close the session off, saying how it ended.
static func end_session(why: String) -> void:
	if _path == "":
		return
	_write("session ended: %s" % why)
	_path = ""


## Leave a numbered marker. Returns which number it was, or 0.
static func note() -> int:
	if _path == "":
		return 0
	_notes += 1
	_write("NOTE %d - the tester marked this moment" % _notes)
	return _notes


## How many markers this session has, for a badge that wants to say so.
static func notes() -> int:
	return _notes


## Where the session is being written, or "".
static func path() -> String:
	return _path


## Whether a session is open.
static func running() -> bool:
	return _path != ""


## Everything that has happened since the last look.
##
## Called once a frame with the live run. Cheap when nothing happened: it
## compares two integers and walks the bounded event list, and writes nothing
## unless there is something to write.
static func watch(state: Dictionary) -> void:
	if _path == "" or state.is_empty():
		return

	var day := int(state.get("day", 0))
	if day != _day:
		if _day != 0:
			_write("day %d ended - %s" % [_day, _built_so_far(state)])
		_day = day
		_write("day %d began" % day)

	var phase := int(state.get("phase", -1))
	if phase != _phase:
		_phase = phase
		_write("%s" % _phase_line(state, phase))

	# **The rules' own record, with a clock beside it.** `Events` is bounded
	# and already ordered, so this is a walk of at most `Events.CAP` entries
	# and a comparison - not a diff of two states.
	var fresh := Events.since(state, _seen)
	for one in fresh:
		var entry: Dictionary = one
		var at := int(entry.get("tick", 0))
		if at < _seen:
			continue
		_write(_event_line(entry))
		_seen = maxi(_seen, at + 1)
		# **The one event that ends a session.** Noticed here rather than by
		# a screen watching for it, because this is already the thing
		# walking the events and a second watcher would drift from it.
		if StringName(entry.get("kind", &"?")) == &"night_lost":
			run_ended(state, "the house fell on night %d"
				% int(entry.get("night", 0)))
			return


## The run is over, one way or the other.
static func run_ended(state: Dictionary, how: String) -> void:
	if _path == "":
		return
	_write("the run ended: %s" % how)
	_write("  reached night %d, day %d, tick %d"
		% [int(state.get("nights_won", 0)) + 1, int(state.get("day", 0)),
			int(state.get("tick", 0))])
	_write("  built %s" % _built_so_far(state))
	end_session(how)


## Every session log on this machine, oldest first.
static func sessions() -> Array:
	if not DirAccess.dir_exists_absolute(DIR):
		return []
	var found: Array = []
	for name in DirAccess.get_files_at(DIR):
		if String(name).ends_with(".log"):
			found.append(DIR.path_join(String(name)))
	found.sort()
	return found


# ------------------------------------------------------------------ the lines

## One line, with the minutes and seconds since the session began.
static func _write(what: String) -> void:
	if _path == "":
		return
	var f := FileAccess.open(_path, FileAccess.READ_WRITE)
	if f == null:
		return
	f.seek_end()
	var gone := int((Time.get_ticks_msec() - _began_ms) / 1000)
	f.store_line("%3d:%02d  %s" % [gone / 60, gone % 60, what])
	f.close()


## What an event says, in words rather than as a dictionary.
##
## **Here rather than in `src/ui/log_panel.gd`**, and deliberately not the
## same sentences: the panel is for a player mid-fight and this is for
## somebody reading afterwards, who wants the numbers.
static func _event_line(entry: Dictionary) -> String:
	var kind := StringName(entry.get("kind", &"?"))
	match kind:
		&"night_began":
			return "night %d began" % int(entry.get("night", 0))
		&"wave_began":
			return "  wave %d of %d - %d %s" % [int(entry.get("wave", 0)),
				int(entry.get("waves", 0)), int(entry.get("count", 0)),
				String(entry.get("enemy", &"?"))]
		&"structure_lost":
			return "  lost a %s" % String(entry.get("id", &"?"))
		&"house_hit":
			return "  the house was hit, %d left" % int(entry.get("left", 0))
		&"crop_ready":
			return "  a %s came ready" % String(entry.get("id", &"?"))
		&"craft_done":
			return "  crafted a %s" % String(entry.get("id", &"?"))
		&"boss_arrived":
			return "  something big arrived"
		&"night_won":
			return "night %d won" % int(entry.get("night", 0))
		&"night_lost":
			return "night %d lost" % int(entry.get("night", 0))
	return "  %s" % String(kind)


static func _phase_line(state: Dictionary, phase: int) -> String:
	match phase:
		Phases.DAY: return "  the day is theirs"
		Phases.PREPARATION: return "  they sent for the night"
		Phases.NIGHT: return "  the night is here"
		Phases.RESULT: return "  the payout is on the screen"
	return "  phase %d" % [phase]


## What is standing, counted by kind, sorted so two logs can be read side by
## side.
static func _built_so_far(state: Dictionary) -> String:
	var stats: Dictionary = state.get("stats", {})
	var by_kind: Dictionary = stats.get("built_by_kind", {})
	if by_kind.is_empty():
		return "nothing built yet"
	var keys: Array = []
	for key in by_kind:
		keys.append(str(key))
	keys.sort()
	var parts := PackedStringArray()
	for key in keys:
		parts.append("%s x%d" % [key, int(by_kind[key])])
	return "built " + ", ".join(parts)
