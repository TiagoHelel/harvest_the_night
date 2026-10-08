class_name Events
extends RefCounted

## A short, bounded record of what just happened, kept by the rules.
##
## **Data, never words.** An event is `{tick, kind, ...}` and nothing in here
## knows what a player reads; `src/ui/log_panel.gd` turns a kind into a
## sentence and a colour, and task 0097 turns that sentence into Portuguese.
## A rule that wrote "the fence came down" would be a rule that had to be
## edited to translate the game.
##
## ## Why the rules keep it at all
##
## Three view systems already work out what happened by comparing this frame
## with the last one - `particles.gd`, `sfx.gd`, `juice.gd` - and that is
## right for a spark, where missing one costs a puff of dust. A **log** is a
## different promise: it says what happened and in what order, and a view that
## samples at whatever rate the machine manages cannot make that promise. At
## four times speed a frame is eight ticks and seven of them are invisible.
##
## So this is the one thing the rules record for the view's benefit, and task
## 0090's requirement says so in as many words. It costs a moved determinism
## hash, which is deliberate and written down in `implementation/PROGRESS.md`.
##
## ## It cannot grow
##
## `CAP` entries, oldest dropped. That is the second done-when, and it is the
## reason this is safe to put in the state at all: an unbounded list in a
## dictionary that gets hashed, saved and copied is a leak with a long fuse.

## How many events are kept. Enough for a busy night's last minute at four
## times speed, small enough that hashing and saving them cost nothing worth
## measuring.
##
## **Not a `# LEVER`.** It is not a number a designer turns to change how the
## game plays; it is how much of a receipt the game keeps.
const CAP := 64

## Every kind the rules can record. The view is checked against this list, so
## a new kind is a log line nobody wrote for exactly as long as it takes to
## run `headless_check`.
const KINDS: Array = [
	&"night_began",
	&"wave_began",
	&"structure_lost",
	&"house_hit",
	&"crop_ready",
	&"craft_done",
	&"boss_arrived",
	&"night_won",
	&"night_lost",
	# Still up at 02:00 (task 0128), and why the build step is short.
	&"passed_out",
	# 06:00 (task 0137): the night won by holding, and how many walked off.
	&"dawn",
]


static func initial() -> Dictionary:
	return {"events": []}


## Write one down.
##
## `data` is whatever the kind needs - a cell, an id, a number - and is copied
## rather than kept by reference, because an event is a record of a moment and
## a dictionary somebody else still holds is not.
static func add(state: Dictionary, kind: StringName,
		data: Dictionary = {}) -> void:
	if not KINDS.has(kind):
		push_error("Events: nothing records '%s'" % kind)
		return
	# **The record owns `tick` and `kind`.** A caller passing either would
	# have it silently overwritten, which is how the first wave event came to
	# name itself instead of the thing that was arriving.
	for taken in ["tick", "kind"]:
		if data.has(taken):
			push_error("Events: '%s' cannot carry a '%s' of its own"
				% [kind, taken])
			return
	var all: Array = state["events"]
	var one := data.duplicate(true)
	one["tick"] = int(state["tick"])
	one["kind"] = kind
	all.append(one)
	# **A window, not a list.** The oldest goes when the newest arrives, so
	# the state never grows however long a night runs.
	while all.size() > CAP:
		all.remove_at(0)


## The last `count` of them, oldest first. The whole record when asked for
## more than there is.
static func recent(state: Dictionary, count: int = CAP) -> Array:
	var all: Array = state["events"]
	if count >= all.size():
		return all.duplicate()
	return all.slice(all.size() - count)


## Everything recorded since a given tick, which is how the night's history is
## sliced out of a record that also holds the end of the day before it.
static func since(state: Dictionary, tick: int) -> Array:
	var out: Array = []
	for one in (state["events"] as Array):
		if int((one as Dictionary)["tick"]) >= tick:
			out.append(one)
	return out


## Drop the lot. Called when a run begins, so a new farm does not open with
## the last one's obituary.
static func clear(state: Dictionary) -> void:
	(state["events"] as Array).clear()
