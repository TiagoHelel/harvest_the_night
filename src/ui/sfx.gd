class_name Sfx
extends Node

## Watches the day happen and asks `Audio` for the noise it made.
##
## **The rules do not know sound exists.** `src/core/` records what happened
## and this reads it, exactly as `particles.gd` reads it to throw sparks. That
## is what keeps a volume slider out of the determinism hash, and it is why
## there is no `Audio.play()` anywhere in `src/core/`.
##
## ## How a finished verb is spotted from outside
##
## A working verb lives in `state["player"]["action"]` as
## `{verb, cell, left, total}`, and `left` falls by one every tick while
## `state["tick"]` rises by one. So **`left + tick` is the tick the cycle is
## due to finish on, and it does not move while the cycle runs.** That one
## invariant answers both awkward questions exactly:
##
## - The due tick jumping forward means a cycle finished and the verb went
##   round again - which is what chopping a tree is, twenty times over.
## - An action that vanished finished if the clock had reached its due tick,
##   and was **interrupted** if it had not. Walking away mid-swing is not a
##   sound, and without this it would be one.
##
## Guessing from "the action disappeared and `left` was small" would have been
## a fudge that failed at four times speed. This is arithmetic.
##
## ## What the action cannot see
##
## Watering is on `Interact.INSTANT`: it never creates an action, because a
## held key has to water a whole row as the player walks it. So it is spotted
## by counting watered plots instead. The bite has no verb at all - it is a
## window opening - and the sale is money arriving while the stall is open.

## Verb -> the sound it makes. A verb absent from here is deliberately silent:
## `repair` is the night's and belongs to task 0085, and asking for a sound
## that does not exist would put a warning in the log on every swing.
const VERB_SOUNDS := {
	&"chop": &"sfx/chop",
	&"mine": &"sfx/mine",
	&"till": &"sfx/till",
	&"plant": &"sfx/plant",
	&"harvest": &"sfx/harvest",
	&"collect": &"sfx/collect",
	&"craft": &"sfx/craft",
	&"trade": &"sfx/trade",
	&"fish": &"sfx/cast",
	&"reel": &"sfx/reel",
}

const WATER_SOUND := &"sfx/water"
const BITE_SOUND := &"sfx/bite"
const SELL_SOUND := &"sfx/sell"

var _state: Dictionary = {}

## The cycle being watched: what it is, where, and the tick it finishes on.
var _verb := &""
var _cell := Vector2i(-1, -1)
var _due := -1

var _was_biting := false
var _watered := -1
var _money := -1

var _audio: Node = null


func show_state(state: Dictionary) -> void:
	_state = state
	# **Nothing is remembered across runs.** A new farm starting with the last
	# one's money on record would play a sale the first time the player sold
	# nothing at all.
	_verb = &""
	_cell = Vector2i(-1, -1)
	_due = -1
	_was_biting = false
	_watered = -1
	_money = -1


func _process(_delta: float) -> void:
	if _state.is_empty():
		return
	if int(_state["phase"]) != Phases.DAY:
		# The farm is asleep after dark and these verbs do not tick then. The
		# counters are reset so that coming back to the farm does not fire a
		# sale for every coin the night paid out.
		_verb = &""
		_due = -1
		_watered = -1
		_money = -1
		return
	_watch_action()
	_watch_water()
	_watch_fishing()
	_watch_money()


# ------------------------------------------------------------------ the verbs

func _watch_action() -> void:
	var player: Dictionary = _state["player"]
	var action: Dictionary = player["action"]
	var tick := int(_state["tick"])

	if action.is_empty():
		if _due >= 0 and tick >= _due:
			_play_verb(_verb)
		_verb = &""
		_cell = Vector2i(-1, -1)
		_due = -1
		return

	var verb := StringName(action["verb"])
	var at := Vector2i(int(action["cell"][0]), int(action["cell"][1]))
	var due := tick + int(action["left"])
	# The same verb on the same cell with its due tick pushed forward is the
	# one that repeated - a held key on a tree that is not down yet.
	if _due >= 0 and verb == _verb and at == _cell and due > _due:
		_play_verb(verb)
	_verb = verb
	_cell = at
	_due = due


func _play_verb(verb: StringName) -> void:
	if verb == &"" or not VERB_SOUNDS.has(verb):
		return
	_ask(VERB_SOUNDS[verb])


# ------------------------------------------------------------- the other three

## Watering, which has no action to watch because it is instant.
func _watch_water() -> void:
	var now := _watered_plots()
	if _watered >= 0 and now > _watered:
		_ask(WATER_SOUND)
	_watered = now


func _watered_plots() -> int:
	var n := 0
	# A count, so the order this comes out in cannot matter - which is the one
	# thing the house rule about unsorted dictionaries is protecting.
	for key in (_state["plots"] as Dictionary):
		if bool((_state["plots"][key] as Dictionary).get("watered", false)):
			n += 1
	return n


## The bite, which is a window opening rather than anything the player did.
func _watch_fishing() -> void:
	var biting := Fishing.is_biting(_state)
	if biting and not _was_biting:
		_ask(BITE_SOUND)
	_was_biting = biting


## A sale: money arriving while the stall is open. Buying spends rather than
## earns, so only the way up makes a noise.
func _watch_money() -> void:
	var now := Resources.amount(_state, GameData.MONEY)
	if _money >= 0 and now > _money and Shop.is_open(_state):
		_ask(SELL_SOUND)
	_money = now


func _ready() -> void:
	# **By path and never by name.** `verify.py` parses each script on its own
	# with no autoloads registered, so a bare `Audio.play(...)` is an
	# undeclared identifier there and the parse row goes red for a file that
	# is perfectly correct at runtime.
	_audio = get_node_or_null(^"/root/Audio")


func _ask(id: StringName) -> void:
	if _audio != null:
		_audio.play(id)
