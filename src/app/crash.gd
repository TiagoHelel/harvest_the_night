class_name Crash

## When it breaks on somebody else's machine, get enough to fix it.
##
## Writes a folder under `user://crash/` holding a readable report and the
## whole run as the game had it. **It sends nothing anywhere**, and it cannot:
## there is no network code in this project at all. The player is told where
## the folder is and decides what to do with it.
##
## ## GDScript has no exceptions, so there are two mechanisms and not one
##
## There is no `try`. A script error prints and the frame carries on with a
## null where a number should be, and a real crash takes the process with it
## before any GDScript runs. So:
##
## 1. **A reported error.** Something notices an impossible state and calls
##    `report()`. Full fidelity - the exact state at the exact tick. This is
##    the one that catches the failures this game will actually have, because
##    the rules are the part with the bugs in and the rules cannot throw.
## 2. **A breadcrumb.** `mark()` writes the same folder under a fixed name
##    every few seconds while a run is going; `clear_mark()` deletes it on the
##    way out. A folder still there at the next boot means the last session
##    did not leave through the door, and `sweep()` promotes it to a report.
##    The tick in it is up to `BREADCRUMB_SECONDS` stale, which is the price
##    of not writing to disk every frame, and it is still the seed, the night
##    and the last thing that happened.
##
## `App` also answers `NOTIFICATION_CRASH`, which the engine sends from its
## own crash handler on desktop. That is the best of the three when it fires
## and the least reliable to count on, which is why the breadcrumb exists.
##
## ## The run save is never touched
##
## Everything here writes inside `user://crash/`. `Save.RUN_PATH` is not
## written, moved or deleted by any path through this file - a crash must not
## cost a player their farm on top of everything else. `headless_check`
## asserts it by crashing on purpose with a run saved and loading it again.

## Where reports go. One folder per crash, so the snapshot can sit next to the
## text that explains it.
const DIR := "user://crash"

## The two files in each one.
const REPORT := "report.txt"
const SNAPSHOT := "state.sav"

## The breadcrumb's folder, which is the only fixed name under `DIR`.
const IN_PROGRESS := "in_progress"

## Dropped in a folder once its dialogue has been shown, so the same crash is
## not announced at every boot for the rest of the game's life.
const SEEN := "seen"

## How many crash folders are kept. The newest are the ones somebody will be
## asked about; an unbounded pile of them in a user folder is litter.
##
## **Not a `# LEVER`.** It changes nothing about how the game plays.
const KEEP := 5

## How many lines of the engine's own log go in. Enough to hold the error and
## what led to it, short enough that the file stays something a person reads.
const LOG_LINES := 40

## How often the breadcrumb is rewritten while a run is going. The run save is
## about fifteen kilobytes, so this is a rounding error against the disk and it
## bounds how stale the recorded tick can be.
const BREADCRUMB_SECONDS := 10.0


## The run the game is in the middle of, for whoever finds out it has
## stopped.
##
## **A crash handler has no arguments.** `NOTIFICATION_CRASH` arrives at an
## autoload that has never seen a run, and the breadcrumb timer would
## otherwise have to be given the state by whoever happens to own it. One
## reference, set when the dictionary is replaced - `SimDriver.start()` makes
## a new one rather than clearing the old - and cleared when the run ends.
static var _live: Dictionary = {}


## Hold on to this run.
static func watch(state: Dictionary) -> void:
	_live = state


## There is no run any more.
static func forget() -> void:
	_live = {}


## Whatever was going, or an empty Dictionary.
static func live() -> Dictionary:
	return _live


## Write a report for `state` and say why. Returns the folder, or "".
##
## The caller decides what `reason` says; it goes in the file verbatim after
## scrubbing, so it may name a function and a value but must not be built out
## of anything a player typed. Nothing in this game asks a player to type.
static func report(state: Dictionary, reason: String) -> String:
	var folder := _fresh_folder()
	if folder == "":
		return ""
	if not _write_folder(folder, state, reason):
		return ""
	_prune()
	return folder


## Rewrite the breadcrumb. Cheap enough for a timer, never for a frame.
##
## Nothing to say when there is no run: a player sitting on the title screen
## has not crashed out of anything, and a breadcrumb for an empty state would
## announce a crash at the next boot that never happened.
static func mark() -> void:
	if _live.is_empty():
		return
	var folder := DIR.path_join(IN_PROGRESS)
	if not _make_dir(folder):
		return
	_write_folder(folder, _live, BREADCRUMB_REASON)


## What a promoted breadcrumb says happened, since nothing was there to say.
const BREADCRUMB_REASON := \
	"the game stopped without closing, and this is the last few seconds " \
	+ "before it went rather than the moment itself"


## The game left through the door. Drop the breadcrumb.
static func clear_mark() -> void:
	erase(DIR.path_join(IN_PROGRESS))


## At boot: turn a surviving breadcrumb into a report. Returns its folder,
## or "" when the last session ended properly.
static func sweep() -> String:
	var crumb := DIR.path_join(IN_PROGRESS)
	if not DirAccess.dir_exists_absolute(crumb):
		return ""
	var folder := _fresh_folder()
	if folder == "":
		erase(crumb)
		return ""
	# A rename inside the same directory is a move, and it keeps the two files
	# together - a report without its snapshot is half a report.
	erase(folder)
	var at := DirAccess.open(DIR)
	if at == null or at.rename(IN_PROGRESS, folder.get_file()) != OK:
		erase(crumb)
		return ""
	_prune()
	return folder


## Every report folder, oldest first. The stamp sorts as the date does.
static func folders() -> Array:
	if not DirAccess.dir_exists_absolute(DIR):
		return []
	var found: Array = []
	for name in DirAccess.get_directories_at(DIR):
		if name == IN_PROGRESS:
			continue
		found.append(DIR.path_join(name))
	found.sort()
	return found


## The newest report nobody has been shown yet, or "".
static func pending() -> String:
	var all := folders()
	all.reverse()
	for folder in all:
		if not FileAccess.file_exists(String(folder).path_join(SEEN)):
			return String(folder)
	return ""


## Remember that this one has been announced.
static func mark_seen(folder: String) -> void:
	if folder == "":
		return
	var f := FileAccess.open(folder.path_join(SEEN), FileAccess.WRITE)
	if f != null:
		f.store_line("shown")
		f.close()


## The report's text, for a screen that wants to show it.
static func text_of(folder: String) -> String:
	if folder == "":
		return ""
	return FileAccess.get_file_as_string(folder.path_join(REPORT))


## Where the folder is in words a player can act on - the real path on disk,
## not the `user://` one, because `user://` is not somewhere anybody can go.
static func where(folder: String) -> String:
	if folder == "":
		return ""
	return ProjectSettings.globalize_path(folder)


## The state the game had when it went, read back from a report.
##
## An empty Dictionary when there is none or it will not decode - a crash
## report is the one file in the game most likely to be damaged.
static func snapshot_of(folder: String) -> Dictionary:
	if folder == "":
		return {}
	var path := folder.path_join(SNAPSHOT)
	if not FileAccess.file_exists(path):
		return {}
	var body := FileAccess.get_file_as_bytes(path)
	if body.size() < 4:
		return {}
	var value: Variant = bytes_to_var(body)
	return value if value is Dictionary else {}


# --------------------------------------------------------------- the writing

static func _write_folder(folder: String, state: Dictionary,
		reason: String) -> bool:
	if not _make_dir(folder):
		return false

	# The snapshot first: if the disk is full or the folder is read-only, a
	# report saying the state was saved when it was not is worse than neither.
	var body := var_to_bytes(state)
	var snap := FileAccess.open(folder.path_join(SNAPSHOT), FileAccess.WRITE)
	if snap == null:
		return false
	snap.store_buffer(body)
	snap.close()

	var f := FileAccess.open(folder.path_join(REPORT), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(scrub(_compose(state, reason, body.size())))
	f.close()
	return true


## The report itself. English, deliberately: the dialogue tells the player
## what is in here in their own language, and this half is for whoever is
## going to read it in order to fix the game.
static func _compose(state: Dictionary, reason: String,
		snap_size: int) -> String:
	var out := PackedStringArray()
	out.append("HARVEST THE NIGHT - crash report")
	out.append("================================")
	out.append("")
	out.append("This file was written on your own machine and sent nowhere.")
	out.append("The game has no network code in it at all - it cannot send")
	out.append("anything, by itself or otherwise. Where this goes is your")
	out.append("decision and nobody else's.")
	out.append("")
	out.append("WHAT IS IN IT")
	out.append("  the build      which version of the game this was")
	out.append("  the run        the seed, the tick, the phase and the day")
	out.append("  what happened  the reason, and the engine's last lines")
	out.append("  the log        the last things the game recorded happening")
	out.append("  the hardware   which system and which graphics card")
	out.append("  %-15sthe whole run beside this file, %d bytes"
		% [SNAPSHOT, snap_size])
	out.append("")
	out.append("WHAT IS NOT")
	out.append("  Your name is not in it. The game never asks for one: there")
	out.append("  is no text box anywhere in it, so there is nowhere a name")
	out.append("  could have got in. No machine name, no addresses, and no")
	out.append("  paths from outside the game's own folder - those are taken")
	out.append("  out on the way in. The run is numbers: how much wood, where")
	out.append("  the fences are, which tick it was.")
	out.append("")
	out.append("  It is text on purpose. Read all of it before you send it.")
	out.append("")
	out.append("THE BUILD")
	out.append("  %s" % BuildInfo.line())
	# **The card, because a picture going wrong is the failure a report
	# cannot show.** A model name is hardware and not a person, and it is
	# listed above rather than slipped in: the header has to be the whole
	# truth about what is in the file or it is worth nothing.
	out.append("  %s, %s" % [OS.get_name(), _adapter()])
	out.append("")
	out.append("WHAT HAPPENED")
	for line in reason.split("\n"):
		out.append("  %s" % line)
	out.append("")
	out.append("THE RUN")
	for line in summary(state):
		out.append("  %s" % line)
	out.append("")
	out.append("THE LOG")
	var events := _events_of(state)
	if events.is_empty():
		out.append("  nothing recorded")
	for line in events:
		out.append("  %s" % line)
	out.append("")
	out.append("THE ENGINE'S LAST %d LINES" % LOG_LINES)
	var tail := _log_tail()
	if tail.is_empty():
		out.append("  no log file - file logging is off, or this is the web")
		out.append("  build, where there is no file to write")
	for line in tail:
		out.append("  %s" % line)
	out.append("")
	return "\n".join(out) + "\n"


## The four numbers somebody needs before anything else, as lines.
##
## Public because the dialogue shows the same ones: a player reading "seed
## 20260927, tick 41230" off the screen and off the file is a player who can
## tell they match.
static func summary(state: Dictionary) -> Array:
	if state.is_empty():
		return ["no run was going"]
	return [
		"seed    %d" % int(state.get("seed", 0)),
		"tick    %d" % int(state.get("tick", 0)),
		"phase   %s" % _phase_name(int(state.get("phase", -1))),
		"day     %d, nights won %d" % [int(state.get("day", 0)),
			int(state.get("nights_won", 0))],
	]


## Which graphics card, when anything can say. The rendering server is not
## there at all in some of the places this can be called from, so a missing
## answer is a line saying so rather than an error inside a crash handler.
static func _adapter() -> String:
	if not Engine.has_singleton("RenderingServer"):
		return "no renderer"
	var named := RenderingServer.get_video_adapter_name()
	return named if named != "" else "no renderer"


static func _phase_name(phase: int) -> String:
	match phase:
		Phases.DAY: return "DAY"
		Phases.PREPARATION: return "PREPARATION"
		Phases.NIGHT: return "NIGHT"
		Phases.RESULT: return "RESULT"
	return "unknown (%d)" % phase


## The game's own log - `Events`, which is data and not words. Turned into
## words here and not by `src/ui/log_panel.gd`, because a crash report is read
## by whoever fixes the game and wants the kind and the tick, not a sentence.
static func _events_of(state: Dictionary) -> Array:
	var lines: Array = []
	for one in Events.recent(state):
		var entry: Dictionary = one
		var extra := PackedStringArray()
		for key in _sorted_keys(entry):
			if key == "tick" or key == "kind":
				continue
			extra.append("%s=%s" % [key, str(entry[key])])
		lines.append("tick %-7d %-16s %s"
			% [int(entry.get("tick", 0)), String(entry.get("kind", &"?")),
				" ".join(extra)])
	return lines


## Sorted, because a Dictionary's order is not a promise and a report that
## reads differently from one run to the next is a report nobody can diff.
static func _sorted_keys(from: Dictionary) -> Array:
	var keys: Array = []
	for key in from:
		keys.append(str(key))
	keys.sort()
	return keys


## The tail of the engine's own log file, if there is one.
static func _log_tail() -> Array:
	var path := str(ProjectSettings.get_setting(
		"debug/file_logging/log_path", "user://logs/godot.log"))
	if not FileAccess.file_exists(path):
		return []
	var whole := FileAccess.get_file_as_string(path)
	var lines := whole.split("\n", false)
	var from := maxi(lines.size() - LOG_LINES, 0)
	var out: Array = []
	for i in range(from, lines.size()):
		out.append(lines[i])
	return out


# ------------------------------------------------------------- the scrubbing

## Take the machine out of the text.
##
## The engine's log prints absolute paths, and on every desktop this game runs
## on an absolute path has the person's account name in it. That is the one
## way personal data gets into a file this game writes, so it is taken out at
## the door rather than promised away in the header.
##
## Short values are left alone: an account called `al` would turn every `al`
## in the file into `<user>` and make the report unreadable, to protect two
## letters that are not a name anyway.
static func scrub(text: String) -> String:
	var out := text
	for secret in _secrets():
		var value := String(secret)
		out = out.replace(value, "<user>")
		out = out.replace(value.replace("\\", "/"), "<user>")
	return out


## The strings that must not survive, longest first - so that a home folder is
## replaced whole rather than left as `<user>/AppData/...` because the account
## name inside it went first.
static func _secrets() -> Array:
	var raw: Array = [
		OS.get_user_data_dir(),
		ProjectSettings.globalize_path("res://"),
		OS.get_environment("USERPROFILE"),
		OS.get_environment("HOME"),
		OS.get_environment("USERNAME"),
		OS.get_environment("USER"),
	]
	var keep: Array = []
	for one in raw:
		var value := str(one)
		if value.length() >= 3 and not keep.has(value):
			keep.append(value)
	keep.sort_custom(_longer_first)
	return keep


static func _longer_first(a: String, b: String) -> bool:
	return a.length() > b.length()


# ----------------------------------------------------------- the housekeeping

## A folder name that does not exist yet. Stamped with the date so the newest
## is the last one alphabetically, and counted so two crashes in one second
## are two folders.
static func _fresh_folder() -> String:
	if not _make_dir(DIR):
		return ""
	var when := Time.get_datetime_dict_from_system()
	var stamp := "%04d%02d%02d-%02d%02d%02d" % [int(when["year"]),
		int(when["month"]), int(when["day"]), int(when["hour"]),
		int(when["minute"]), int(when["second"])]
	var folder := DIR.path_join(stamp)
	var nth := 2
	while DirAccess.dir_exists_absolute(folder) and nth < 100:
		folder = DIR.path_join("%s-%d" % [stamp, nth])
		nth += 1
	return folder


static func _make_dir(path: String) -> bool:
	if DirAccess.dir_exists_absolute(path):
		return true
	return DirAccess.make_dir_recursive_absolute(path) == OK


## Keep the newest `KEEP`, delete the rest.
static func _prune() -> void:
	var all := folders()
	var over := all.size() - KEEP
	for i in range(0, maxi(over, 0)):
		erase(String(all[i]))


## Remove a folder and the files in it. One level deep, because that is all a
## report folder ever is, and a recursive delete in a tool that runs after a
## crash is a bad way to find out about a bug in the path.
##
## Public because three things make reports that are not crashes - two checks
## and the screenshot tool - and a tool that leaves one behind has put a
## dialogue in front of the next person to open the game.
static func erase(folder: String) -> void:
	if not DirAccess.dir_exists_absolute(folder):
		return
	var at := DirAccess.open(folder)
	if at == null:
		return
	for name in at.get_files():
		at.remove(name)
	DirAccess.remove_absolute(folder)
